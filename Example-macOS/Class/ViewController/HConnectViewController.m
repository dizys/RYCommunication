//
//  HConnectViewController.m
//  PoooliExample
//
//  Created by ldc on 2019/12/2.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import "HConnectViewController.h"
#import <RYCommunication-macOS/RYCommunication-macOS.h>

@interface HConnectViewController ()<NSTableViewDelegate, NSTableViewDataSource>

@property (weak) IBOutlet NSScrollView *scrollView;

@property (weak) IBOutlet NSTableView *tableView;

@property (weak) IBOutlet NSButton *continueScanButton;

@property (weak) IBOutlet NSButton *connectButton;

@property (nonatomic, strong) HUSBBrowser *usbBrowser;

@property (nonatomic, strong) HBluetoothBrowser *bluetoothBrowser;

@end

@implementation HConnectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.headerView.frame = CGRectZero;
}

- (IBAction)continueScanAction:(NSButton *)sender {
    
    sender.enabled = false;
    [self.bluetoothBrowser startScan:false complete:^{
        self.continueScanButton.enabled = true;
        [self.tableView reloadData];
    }];
}

- (IBAction)connectAction:(NSButton *)sender {
    
    switch (self.interfaceType) {
        case HInterfaceTypeBluetooth:
            [self bluetoothConnectAction];
            break;
        case HInterfaceTypeUSB:
            [self usbConnectAction];
            break;
        default:
            break;
    }
}

- (void)setInterfaceType:(HInterfaceType)interfaceType {
    
    _interfaceType = interfaceType;
    switch (interfaceType) {
        case HInterfaceTypeUSB:
            [self startUSBScan];
            break;
        case HInterfaceTypeBluetooth:
            [self startBluetoothScan];
        default:
            break;
    }
}

- (void)usbConnectAction {
    
    HUSBDevice *u = self.usbBrowser.interfaces[self.tableView.selectedRow];
    self.connectButton.enabled = false;
    [u connect:^{
        if (self.connectBlock) {
            self.connectBlock(u);
        }
        [self dismissController:nil];
    } fail:^(NSError * _Nonnull error) {
        HUSBConnectErrorCode code = error.code;
        switch (code) {
            case HUSBConnectErrorCodeDidConnect:
                [self showConnectError:@"设备已连接"];
                break;
            case HUSBConnectErrorCodeBeginReadPipe:
                [self showConnectError:@"开始读取数据失败"];
                break;
            case HUSBConnectErrorCodeInterfaceOpen:
                [self showConnectError:@"接口打开失败"];
                break;
            case HUSBConnectErrorCodeInPipeNotFound:
                [self showConnectError:@"没有找到输入管线"];
                break;
            case HUSBConnectErrorCodeOutPipeNotFound:
                [self showConnectError:@"没有找到输出管线"];
                break;
            case HUSBConnectErrorCodeQueryInterface:
                [self showConnectError:@"插件接口获取接口失败"];
                break;
            case HUSBConnectErrorCodeGetNumEndpoints:
                [self showConnectError:@"获取终结点失败"];
                break;
            case HUSBConnectErrorCodeCreatePlugInInterface:
                [self showConnectError:@"创建插件接口失败"];
                break;
            case HUSBConnectErrorCodeCreateAsyncEventSource:
                [self showConnectError:@"创建异步活动源失败"];
                break;
            case HUSBConnectErrorCodeInterfaceinterfaceServiceNotFound:
                [self showConnectError:@"没有找到接口服务"];
                break;
            default:
                break;
        }
        self.connectButton.enabled = true;
    }];
}

- (void)startBluetoothScan {
    
    self.bluetoothBrowser = [HBluetoothBrowser new];
    [self.bluetoothBrowser startScan:false complete:^{
        self.continueScanButton.enabled = true;
        [self.tableView reloadData];
    }];
}

- (void)bluetoothConnectAction {
    
    HBluetoothDevice *b = self.bluetoothBrowser.devices[self.tableView.selectedRow];
    self.connectButton.enabled = false;
    [b connect:^{
        if (self.connectBlock) {
            self.connectBlock(b);
        }
        [self dismissController:nil];
    } fail:^(NSError * _Nonnull error) {
        self.connectButton.enabled = true;
        HBluetoothConnectErrorCode code = error.code;
        switch (code) {
            case HBluetoothConnectErrorCodeDidConnect:
                [self showConnectError:@"设备已连接"];
                break;
            case HBluetoothConnectErrorCodeOpenBaseband:
                [self showConnectError:@"基带打开失败"];
                break;
            case HBluetoothConnectErrorCodeSDPQuery:
                [self showConnectError:@"SDP服务请求失败"];
                break;
            case HBluetoothConnectErrorCodeSDPServiceNotFound:
                [self showConnectError:@"没找到合适的服务"];
                break;
            case HBluetoothConnectErrorCodeGetRFCOMMChannel:
                [self showConnectError:@"服务获取RFCOMM通道失败"];
                break;
            case HBluetoothConnectErrorCodeOpenRFCOMMChannel:
                [self showConnectError:@"RFCOMM通道打开失败"];
                break;
            case HBluetoothConnectErrorCodeAuthTimeout:
                [self showConnectError:@"设备授权超时"];
                break;
            case HBluetoothConnectErrorCodeAuthFail:
                [self showConnectError:@"请求授权被拒"];
                break;
            default:
                break;
        }
    }];
}

- (void)showConnectError:(NSString *)msg {
    
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"确定"];
    [alert setMessageText:@"连接失败"];
    [alert setInformativeText:msg];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:[self.view window] completionHandler:nil];
}

- (void)startUSBScan {
    
    self.usbBrowser = [HUSBBrowser share];
    if (!self.usbBrowser.isScanning) {
//        NSDictionary *predicate = @{HUSBVendorIdKey: @(0x20d1), HUSBProductIdKey: @(0x7008)};
        [self.usbBrowser scanInterfaces:nil];
    }
    __weak typeof(self) weakSelf = self;
    self.usbBrowser.interfaceAddBlock = ^(HUSBDevice * _Nonnull interface) {
        [weakSelf.tableView reloadData];
    };
    self.usbBrowser.interfaceRemoveBlock = ^(HUSBDevice * _Nonnull interface) {
        [weakSelf.tableView reloadData];
    };
    [self.tableView reloadData];
}

- (void)dismissController:(id)sender {
    
    switch (self.interfaceType) {
        case HInterfaceTypeBluetooth:
            [self.bluetoothBrowser stopScan:false];
            break;
        default:
            [self.usbBrowser stopScanInterfaces];
            break;
    }
    [super dismissController:sender];
}

#pragma mark --NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    switch (self.interfaceType) {
        case HInterfaceTypeUSB:
            cell.textField.stringValue = self.usbBrowser.interfaces[row].name ?: @"unknown";
            break;
        case HInterfaceTypeBluetooth:
            cell.textField.stringValue = self.bluetoothBrowser.devices[row].name ?: @"unknown";
            break;
        default:
            cell.textField.stringValue = @"unknown";
            break;
    }
    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    
    self.connectButton.enabled = self.tableView.selectedRow != -1;
}

#pragma mark --NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    
    if (!self.bluetoothBrowser && !self.usbBrowser) {
        return 0;
    }
    switch (self.interfaceType) {
        case HInterfaceTypeUSB:
            return self.usbBrowser.interfaces.count;
        case HInterfaceTypeBluetooth:
            return self.bluetoothBrowser.devices.count;
        default:
            return 0;
    }
}

@end
