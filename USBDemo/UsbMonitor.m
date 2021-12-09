//
//  UsbMonitor.m
//  USBDemo
//
//  Created by golfy on 2021/10/18.
//

#import "UsbMonitor.h"
 
@implementation UsbMonitor
 
@synthesize arrayDevices;
@synthesize delegate;
 
static UsbMonitor *sharedInstance = nil;
 
IONotificationPortRef    gNotifyPort;
io_iterator_t            gAddedIter;
CFRunLoopRef             gRunLoop;
unsigned char*           readBuffer;
unsigned char            lastReadBufferEndPoint;
unsigned char            curReadBufferEndPoint;
 
 
void SignalHandler(int sigraised) {
    fprintf(stderr, "\nInterrupted.\n");
    exit(0);
}
 
//  DeviceNotification
//
//  This routine will get called whenever any kIOGeneralInterest notification happens.  We are
//  interested in the kIOMessageServiceIsTerminated message so that's what we look for.  Other
//  messages are defined in IOMessage.h.
//
void DeviceNotification(void *refCon, io_service_t service, natural_t messageType, void *messageArgument) {
    kern_return_t    kr;
    DeviceObject    *privateDataRef = (__bridge DeviceObject *) refCon;
    
    if (messageType == kIOMessageServiceIsTerminated) {
        for (DeviceObject* usbObj in [UsbMonitor sharedUsbMonitorManager].arrayDevices) {
            if (usbObj.locationID == privateDataRef.locationID) {
                NSLog(@"delete id=%08x",usbObj.locationID);
                [[UsbMonitor sharedUsbMonitorManager].arrayDevices removeObject:usbObj];
                break;
            }
        }
        
        if ([[UsbMonitor sharedUsbMonitorManager].delegate respondsToSelector:@selector(usbDidRemove:)]) {
            [[UsbMonitor sharedUsbMonitorManager].delegate usbDidRemove:privateDataRef];
        }
        
        // Free the data we're no longer using now that the device is going away
        CFRelease(privateDataRef.deviceName);
        
        if (privateDataRef.interface) {
            (*(privateDataRef.interface))->USBInterfaceClose(privateDataRef.interface);
            (*(privateDataRef.interface))->Release(privateDataRef.interface);
        }
        
        if (privateDataRef.dev) {
            (*(privateDataRef.dev))->USBDeviceClose(privateDataRef.dev);
            kr = (*privateDataRef.dev)->Release(privateDataRef.dev);
        }
        
        kr = IOObjectRelease(privateDataRef.notification);
        
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
}
 
//  DeviceAdded
//
//  This routine is the callback for our IOServiceAddMatchingNotification.  When we get called
//  we will look at all the devices that were added and we will:
//
//  1.  Create some private data to relate to each device (in this case we use the service's name
//      and the location ID of the device
//  2.  Submit an IOServiceAddInterestNotification of type kIOGeneralInterest for this device,
//      using the refCon field to store a pointer to our private data.  When we get called with
//      this interest notification, we can grab the refCon and access our private data.
//
void DeviceAdded(void *refCon, io_iterator_t iterator) {
    kern_return_t        kr;
    io_service_t        usbDevice;
    IOCFPlugInInterface    **plugInInterface = NULL;
    SInt32                score;
    HRESULT             res;
    
    while ((usbDevice = IOIteratorNext(iterator))) {
        io_name_t        deviceName;
        CFStringRef        deviceNameAsCFString;
        DeviceObject    *privateDataRef = [[DeviceObject alloc]init];  // Create a buffer to hold the data.
        UInt32            locationID;
        
        // Add some app-specific information about this device.
        // Get the USB device's name.
        kr = IORegistryEntryGetName(usbDevice, deviceName);
        if (KERN_SUCCESS != kr) {
            deviceName[0] = '\0';
        }
        
        deviceNameAsCFString = CFStringCreateWithCString(kCFAllocatorDefault,deviceName,kCFStringEncodingASCII);
        
        // Save the device's name to our private data.
        privateDataRef.deviceName = deviceNameAsCFString;
        // Now, get the locationID of this device. In order to do this, we need to create an IOUSBDeviceInterface
        // for our device. This will create the necessary connections between our userland application and the
        // kernel object for the USB Device.
        kr = IOCreatePlugInInterfaceForService(usbDevice,kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID,&plugInInterface, &score);
        
        if ((kIOReturnSuccess != kr) || !plugInInterface) {
            if ([[UsbMonitor sharedUsbMonitorManager].delegate respondsToSelector:@selector(usbOpenFail)]) {
                [[UsbMonitor sharedUsbMonitorManager].delegate usbOpenFail];
            }
            NSLog(@"IOCreatePlugInInterfaceForService returned 0x%08x.",kr);
            continue;
        }
        
        IOUSBDeviceInterface     **oneDev = NULL;
        // Use the plugin interface to retrieve the device interface.
        res = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),(LPVOID*)&oneDev);
        privateDataRef.dev = oneDev;
        
        // Now done with the plugin interface.
        (*plugInInterface)->Release(plugInInterface);
        if (res || privateDataRef.dev == NULL) {
            if ([[UsbMonitor sharedUsbMonitorManager].delegate respondsToSelector:@selector(usbOpenFail)]) {
                [[UsbMonitor sharedUsbMonitorManager].delegate usbOpenFail];
            }
            NSLog(@"QueryInterface returned %d.\n", (int)res);
            continue;
        }
        
        // Now that we have the IOUSBDeviceInterface, we can call the routines in IOUSBLib.h.
        // In this case, fetch the locationID. The locationID uniquely identifies the device
        // and will remain the same, even across reboots, so long as the bus topology doesn't change.
        kr = (*privateDataRef.dev)->GetLocationID(privateDataRef.dev, &locationID);
        if (KERN_SUCCESS != kr) {
            if ([[UsbMonitor sharedUsbMonitorManager].delegate respondsToSelector:@selector(usbOpenFail)]) {
                [[UsbMonitor sharedUsbMonitorManager].delegate usbOpenFail];
            }
            NSLog(@"GetLocationID returned 0x%08x.\n", kr);
            continue;
        } else {
            NSLog(@"Location ID: 0x%08x", locationID);
        }
        privateDataRef.locationID = locationID;
        
        kr = (*privateDataRef.dev)->USBDeviceOpen(privateDataRef.dev);
        if(kr != kIOReturnSuccess) {
            if ([[UsbMonitor sharedUsbMonitorManager].delegate respondsToSelector:@selector(usbOpenFail)]) {
                [[UsbMonitor sharedUsbMonitorManager].delegate usbOpenFail];
            }
            NSLog(@"Usb Open Fail!");
            (*privateDataRef.dev)->USBDeviceClose(privateDataRef.dev);
            (void) (*privateDataRef.dev)->Release(privateDataRef.dev);
            privateDataRef.dev = NULL;
            continue;
        }
        
        //configure device
        UInt8                numConfig;
        IOUSBConfigurationDescriptorPtr configDesc;
        
        //Get the number of configurations.
        kr = (*privateDataRef.dev)->GetNumberOfConfigurations(privateDataRef.dev, &numConfig);
        if(numConfig == 0)
            continue;
        
        //Get the configuration descriptor for index 0
        kr = (*privateDataRef.dev)->GetConfigurationDescriptorPtr(privateDataRef.dev, 0, &configDesc);
        if(kr != kIOReturnSuccess) {
            if ([[UsbMonitor sharedUsbMonitorManager].delegate respondsToSelector:@selector(usbOpenFail)]) {
                [[UsbMonitor sharedUsbMonitorManager].delegate usbOpenFail];
            }
            NSLog(@"Unable to get configuration descriptor for index 0 (err = %08x)\n",kr);
            continue;
        }
        kr = [[UsbMonitor sharedUsbMonitorManager] FindUSBInterface:privateDataRef];
        if (kr != kIOReturnSuccess) {
            if ([[UsbMonitor sharedUsbMonitorManager].delegate respondsToSelector:@selector(usbOpenFail)]) {
                [[UsbMonitor sharedUsbMonitorManager].delegate usbOpenFail];
            }
            NSLog(@"Interface Open Fail!");
            (*privateDataRef.dev)->USBDeviceClose(privateDataRef.dev);
            (*privateDataRef.dev)->Release(privateDataRef.dev);
            privateDataRef.dev = NULL;
            continue ;
        }
        
        io_object_t              oneIter;
        // Register for an interest notification of this device being removed. Use a reference to our
        // private data as the refCon which will be passed to the notification callback.
        kr = IOServiceAddInterestNotification(gNotifyPort,                      // notifyPort
                                              usbDevice,                        // service
                                              kIOGeneralInterest,               // interestType
                                              DeviceNotification,               // callback
                                              (__bridge void*)privateDataRef,   // refCon
                                              &oneIter                          // notification
                                              );
        privateDataRef.notification = oneIter;
        
        if (KERN_SUCCESS != kr) {
            if ([[UsbMonitor sharedUsbMonitorManager].delegate respondsToSelector:@selector(usbOpenFail)]) {
                [[UsbMonitor sharedUsbMonitorManager].delegate usbOpenFail];
            }
            NSLog(@"IOServiceAddInterestNotification returned 0x%08x", kr);
        }
        
        // Done with this USB device; release the reference added by IOIteratorNext
        kr = IOObjectRelease(usbDevice);
    }
}
 
void usbMonitorCallBack(void *refcon, IOReturn result, void *arg0) {
    if (result != kIOReturnSuccess) {
        NSLog(@"...返回错误....");
        return;
    }
    
//    long len = (long)arg0;


    if ([[UsbMonitor sharedUsbMonitorManager].delegate respondsToSelector:@selector(didReceiveDataDevice:readBuffer:)] && (readBuffer != NULL)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UsbMonitor sharedUsbMonitorManager].delegate didReceiveDataDevice:(__bridge DeviceObject *)refcon readBuffer:readBuffer];
        });
    }

//    curReadBufferEndPoint = readBuffer[63];
//    if (!((lastReadBufferEndPoint == 255 && curReadBufferEndPoint == 0) ||  // 两个包连接的判断
//        ((curReadBufferEndPoint - lastReadBufferEndPoint) == 1))) {   // 判断包是否连续
//        [UsbMonitor sharedUsbMonitorManager].lostReadBufferPointCount++;
//    }
//
//    lastReadBufferEndPoint = curReadBufferEndPoint;
//    [UsbMonitor sharedUsbMonitorManager].readBufferPointCount++;
    
//    CFRunLoopStop(CFRunLoopGetCurrent());
    
    
    
    [[UsbMonitor sharedUsbMonitorManager] readPipeAsync];
}
 

 
+ (UsbMonitor *)sharedUsbMonitorManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sharedInstance == nil)
            sharedInstance = [(UsbMonitor *)[super allocWithZone:NULL] init];
    });
    return sharedInstance;
}
 
+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedUsbMonitorManager];
}
 
- (id)copyWithZone:(NSZone *)zone {
    return self;
}
 
- (id)initWithVID:(long)vid withPID:(long)pid {
    self = [super init];
    if (self) {
        
        // Set up the matching criteria for the devices we're interested in. The matching criteria needs to follow
        // the same rules as kernel drivers: mainly it needs to follow the USB Common Class Specification, pp. 6-7.
        // See also Technical Q&A QA1076 "Tips on USB driver matching on Mac OS X"
        // <http://developer.apple.com/qa/qa2001/qa1076.html>.
        // One exception is that you can use the matching dictionary "as is", i.e. without adding any matching
        // criteria to it and it will match every IOUSBDevice in the system. IOServiceAddMatchingNotification will
        // consume this dictionary reference, so there is no need to release it later on.
        CFMutableDictionaryRef matchingDict = IOServiceMatching(kIOUSBDeviceClassName);   // Interested in instances of class
        if (matchingDict == NULL) {
            return nil;
        }
        [self serviceAddMatchingNotificationWithVID:vid withPID:pid matchingDict:matchingDict];
        
    }
    return self;
}
 
- (id)initWithVID:(long)vid withPID:(long)pid withDelegate:(id<UsbMonitorDelegate>)gate {
    self = [super init];
    if (self) {
        
        delegate = gate;
        CFMutableDictionaryRef matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
        if (matchingDict == NULL) {
            return nil;
        }
        [self serviceAddMatchingNotificationWithVID:vid withPID:pid matchingDict:matchingDict];
        
    }
    return self;
}


- (void)serviceAddMatchingNotificationWithVID:(long)vid withPID:(long)pid matchingDict:(CFMutableDictionaryRef)matchingDict {
    
    arrayDevices = [NSMutableArray new];
    
    CFRunLoopSourceRef        runLoopSource;
    CFNumberRef                numberRef;
    kern_return_t            kr;
    long                    usbVendor = vid;
    long                    usbProduct = pid;
    
//        sig_t                    oldHandler;
//
//        oldHandler = signal(SIGINT, SignalHandler);
//        if (oldHandler == SIG_ERR) {
//            fprintf(stderr, "Could not establish new signal handler.");
//        }
    
    // We are interested in all USB devices (as opposed to USB interfaces).  The Common Class Specification
    // tells us that we need to specify the idVendor, idProduct, and bcdDevice fields, or, if we're not interested
    // in particular bcdDevices, just the idVendor and idProduct.  Note that if we were trying to match an
    // IOUSBInterface, we would need to set more values in the matching dictionary (e.g. idVendor, idProduct,
    // bInterfaceNumber and bConfigurationValue.
    
    // Create a CFNumber for the idVendor and set the value in the dictionary
    numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbVendor);
    CFDictionarySetValue(matchingDict,CFSTR(kUSBVendorID),numberRef);
    CFRelease(numberRef);
    
    // Create a CFNumber for the idProduct and set the value in the dictionary
    numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbProduct);
    CFDictionarySetValue(matchingDict,CFSTR(kUSBProductID),numberRef);
    CFRelease(numberRef);
    numberRef = NULL;
    
    // Create a notification port and add its run loop event source to our run loop
    // This is how async notifications get set up.
    gNotifyPort = IONotificationPortCreate(kIOMasterPortDefault);
    runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);

    gRunLoop = CFRunLoopGetCurrent();
    CFRunLoopAddSource(gRunLoop, runLoopSource, kCFRunLoopDefaultMode);
    
    // Now set up a notification to be called when a device is first matched by I/O Kit.
    kr = IOServiceAddMatchingNotification(gNotifyPort,                  // notifyPort
                                          kIOFirstMatchNotification,    // notificationType
                                          matchingDict,                 // matching
                                          DeviceAdded,                  // callback
                                          NULL,                         // refCon
                                          &gAddedIter                   // notification
                                          );
    
    // Iterate once to get already-present devices and arm the notification
    DeviceAdded(NULL, gAddedIter);
    
    // Start the run loop. Now we'll receive notifications.
//    CFRunLoopRun();
}
 
-(void)dealloc {
    for (DeviceObject* dev in arrayDevices) {
        (*(dev.interface))->USBInterfaceClose(dev.interface);
        (*(dev.interface))->Release(dev.interface);
        (*(dev.dev))->USBDeviceClose(dev.dev);
        (*(dev.dev))->Release(dev.dev);
    }
    [arrayDevices removeAllObjects];
}
 
-(IOReturn) FindUSBInterface:(DeviceObject*)usbObject {
    IOReturn                        kr = kIOReturnError;
    IOUSBFindInterfaceRequest       request;
    io_iterator_t                   iterator;
    io_service_t                    usbInterface;
    IOCFPlugInInterface             **plugInInterface = NULL;
    IOUSBInterfaceInterface         **interface = NULL;
    HRESULT                         result;
    SInt32                          score;
    UInt8                           interfaceNumEndpoints;
    UInt8                           pipeRef;
    UInt16                          maxPacketSize = 0;
    UInt8                           pipeIn = 0xff;
    UInt8                           pipeOut = 0xff;
    UInt16                          maxPacketSizeIn = 0;
    UInt16                          maxPacketSizeOut = 0;
    
    //Iterate all usb interface
    request.bInterfaceClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
    request.bAlternateSetting = kIOUSBFindInterfaceDontCare;
    
    //Get an iterator for the interfaces on the device
    kr = (*usbObject.dev)->CreateInterfaceIterator(usbObject.dev, &request, &iterator);
    if(kr != kIOReturnSuccess) {
        NSLog(@"Unable to CreateInterfaceIterator %08x\n", kr);
        return kr;
    }
    
    kr = kIOReturnError;
    while((usbInterface = IOIteratorNext(iterator))) {
        pipeIn = 0xff;
        pipeOut = 0xff;
        kr = IOCreatePlugInInterfaceForService(usbInterface,                                               kIOUSBInterfaceUserClientTypeID, kIOCFPlugInInterfaceID,                                               &plugInInterface, &score);
        kr = IOObjectRelease(usbInterface);
        if(kr != kIOReturnSuccess || !plugInInterface) {
            NSLog(@"Unable to create a plug-in (%08x)\n", kr);
            break;
        }
        
        result = (*plugInInterface)->QueryInterface(plugInInterface,                           CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID), (LPVOID *)&interface);
        IODestroyPlugInInterface(plugInInterface);
        if(result || !interface) {
            NSLog(@"Unable to create a interface for the device interface %08x\n",(int)result);
            break;
        }
        //kr = (*interface)->USBInterfaceClose(interface);
        kr = (*interface)->USBInterfaceOpen(interface);
        if(kr != kIOReturnSuccess) {
            NSLog(@"Unable to open interface for the device interface %08x\n", kr);
            (*interface)->USBInterfaceClose(interface);
            (void) (*interface)->Release(interface);
            interface = NULL;
            break;
        }
        kr = (*interface)->GetNumEndpoints(interface, &interfaceNumEndpoints);
        if(kr != kIOReturnSuccess) {
            (void) (*interface)->USBInterfaceClose(interface);
            (void) (*interface)->Release(interface);
            interface = NULL;
            break;
        }
        for(pipeRef = 1; pipeRef <= interfaceNumEndpoints; pipeRef++) {
            IOReturn     kr2;
            UInt8        direction;
            UInt8        number;
            UInt8        transferType;
            UInt8        interval;
            
            kr2 = (*interface)->GetPipeProperties(interface, pipeRef, &direction,&number, &transferType, &maxPacketSize, &interval);
            if(kr2 != kIOReturnSuccess) {
                NSLog(@"Unable to get properties of pipe %d (%08x)\n",pipeRef, kr2);
            } else {
                if(transferType == kUSBBulk) {
//                    if(direction == kUSBIn) {
                    if(direction == kUSBIn && pipeIn == 0xff) {
                        pipeIn = pipeRef;
                        maxPacketSizeIn = maxPacketSize;
                    }
                    else if(direction == kUSBOut) {
                        pipeOut = pipeRef;
                        maxPacketSizeOut = maxPacketSize;
                    }
                }
            }
        }
        if (pipeIn != 0xff && pipeOut != 0xff) {
            usbObject.interface = interface;
            usbObject.pipeIn = pipeIn;
            usbObject.pipeOut = pipeOut;
            usbObject.maxPacketSizeIn = maxPacketSizeIn;
            usbObject.maxPacketSizeOut = maxPacketSizeOut;
            BOOL isIn = NO;
            for (DeviceObject* obj in arrayDevices) {
                if (obj.locationID == usbObject.locationID) {
                    isIn = YES;
                    break ;
                }
            }
            if (!isIn) {
                [arrayDevices addObject:usbObject];
            }
            if ([delegate respondsToSelector:@selector(usbDidPlunIn:)]) {
                [delegate usbDidPlunIn:usbObject];
            }
            
            return kIOReturnSuccess;
        }
        (*interface)->USBInterfaceClose(interface);
        (*interface)->Release(interface);
        interface = NULL;
    }
    return kr;
}
 
- (DeviceObject*)getObjectByID:(long)localid {
    for (DeviceObject* obj in arrayDevices) {
        if (obj.locationID == localid) {
            return obj;
        }
    }
    return nil;
}
 
//同步
-(IOReturn)WriteSync:(DeviceObject*)pDev buffer:(unsigned char*) writeBuffer size:(unsigned int)size
{
    if (pDev && pDev.interface) {
//        if(size <= pDev.maxPacketSizeOut) {
//            return [self WriteAsync:pDev buffer:writeBuffer size:size];
//        }
        
        _rw = ReadWriteStateWrite;
        kern_return_t kr = 0;
        unsigned char *tmp = writeBuffer;
        unsigned int nWrite = (size > pDev.maxPacketSizeOut ? pDev.maxPacketSizeOut : size);
        unsigned int nLeft = size;
        while(1) {
            if((int)nLeft <= 0) {
                break;
            }
            kr = (*(pDev.interface))->WritePipe(pDev.interface,pDev.pipeOut, (void *)tmp, nWrite);
            if(kr != kIOReturnSuccess)
                break;
            tmp += nWrite;
            nLeft -= nWrite;
            nWrite = (nLeft > pDev.maxPacketSizeOut ? pDev.maxPacketSizeOut : nLeft);
        }
        return kr;
    }
    
    return kIOReturnNoDevice;
}
 
//异步
-(IOReturn)WriteAsync:(DeviceObject*)pDev buffer:(unsigned char*)writeBuffer size:(unsigned int)size {
    if (pDev == nil||pDev.interface == nil) {
        return kIOReturnNoDevice;
    }
    
    _rw = ReadWriteStateWrite;
    IOReturn                  err;
    CFRunLoopSourceRef        cfSource;
    unsigned int*             pWrite = NULL;
    
    err = (*(pDev.interface))->CreateInterfaceAsyncEventSource(pDev.interface, &cfSource);
    if (err) {
        NSLog(@"transferData: unable to create event source, err = %08x\n", err);
        return err;
    }
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), cfSource, kCFRunLoopDefaultMode);
    
    err = (*(pDev.interface))->WritePipeAsync(pDev.interface, pDev.pipeOut, (void *)writeBuffer, size,                                         (IOAsyncCallback1)usbMonitorCallBack, (__bridge void*)pDev);
    if (err != kIOReturnSuccess) {
        NSLog(@"transferData: WritePipeAsyncFailed, err = %08x\n", err);
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), cfSource, kCFRunLoopDefaultMode);
        *pWrite = 0;
        return err;
    }
    
    CFRunLoopRun();
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), cfSource, kCFRunLoopDefaultMode);
    
    return err;
}
 
-(IOReturn)ReadSync:(DeviceObject*)pDev buffer:(unsigned char*)buff size:(unsigned int)size {
    if (pDev && pDev.interface) {
//        if(sizeof(buff) <= pDev.maxPacketSizeIn) {
//            return [self ReadAsync:pDev buffer:buff size:size];
//        }
        _rw = ReadWriteStateRead;
        kern_return_t kr = 0;
        UInt32 nRead = pDev.maxPacketSizeIn;
        unsigned int nLeft = size;
        char *tmp = (char *)buff;
        
        while(1) {
            if((int)nLeft <= 0)
                break;
            
            kr = (*(pDev.interface))->ReadPipe(pDev.interface, pDev.pipeIn, (void *)tmp, &nRead);
            if(kr != kIOReturnSuccess) {
                printf("transferData: Readsync Failed, err = %08x\n", kr);
                break;
            }
            
            tmp += nRead;
            nLeft -= nRead;
            nRead = pDev.maxPacketSizeIn;
        }
        int nRet = ((int)nLeft > 0 ? nLeft : 0);
        size = size - nRet;
        return kr;
    }
    return kIOReturnNoDevice;
}
 
-(IOReturn)ReadAsync:(DeviceObject*)pDev buffer:(unsigned char*)buff size:(unsigned int)size {
    if (pDev == nil||pDev.interface == nil) {
        return kIOReturnNoDevice;
    }
    readBuffer = buff;
    _rw = ReadWriteStateRead;
    _lostReadBufferPointCount = -1;
    lastReadBufferEndPoint = 0;
    curReadBufferEndPoint = 0;
    _readBufferPointCount = 0;
    
    IOReturn                    err;
    CFRunLoopSourceRef          cfSource;
    unsigned int*               pRead = NULL;   
    
    //set up async completion notifications
    err = (*(pDev.interface))->CreateInterfaceAsyncEventSource(pDev.interface, &cfSource);
    if (err) {
        NSLog(@"transferData: unable to create event source, err = %08x\n", err);
        return err;
    }
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), cfSource, kCFRunLoopDefaultMode);
    
    err = (*(pDev.interface))->ReadPipeAsync(pDev.interface, pDev.pipeIn, readBuffer, size,(IOAsyncCallback1)usbMonitorCallBack, (__bridge void*)pDev);
    if (err != kIOReturnSuccess) {
        NSLog(@"transferData: size %u, ReadAsyncFailed, err = %08x\n", size, err);
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), cfSource, kCFRunLoopDefaultMode);
        pRead = nil;
        pDev = nil;
        return err;
    }
    
    CFRunLoopRun();
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), cfSource, kCFRunLoopDefaultMode);
    
    return err;
}
 
- (void)readPipeAsync {
    NSArray *tmpDeviceArray = [self getDeviceArray];
    if (tmpDeviceArray.count > 0) {
        IOReturn                    err;
        unsigned int*               pRead = NULL;
        DeviceObject *pDev = tmpDeviceArray[0];
        err = (*(pDev.interface))->ReadPipeAsync(pDev.interface, pDev.pipeIn, readBuffer, TG_CMD_BUFFER_LEN,(IOAsyncCallback1)usbMonitorCallBack, (__bridge void*)pDev);
        if (err != kIOReturnSuccess) {
            NSLog(@"transferData: size %u, ReadAsyncFailed, err = %08x\n", TG_CMD_BUFFER_LEN, err);
            pRead = nil;
            pDev = nil;
        }
        self.rw = ReadWriteStateRead;
    }
}

- (NSMutableArray*)getDeviceArray {
    return arrayDevices;
}
 
@end
