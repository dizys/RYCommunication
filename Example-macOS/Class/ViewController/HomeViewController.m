//
//  ViewController.m
//  PoooliExample
//
//  Created by ldc on 2019/12/2.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import "HomeViewController.h"
#import "HConnectViewController.h"
#import <RYCommunication-macOS/RYCommunication-macOS.h>
#import "HPoooliCmdSampleGenerator.h"
#import "MTCmdSampleGenerator.h"

typedef NS_ENUM(NSUInteger, HCmdType) {
    HCmdTypeNomal,
    HCmdTypeA4,
};

@interface HomeViewController ()<NSTableViewDelegate, NSTableViewDataSource>

@property (weak) IBOutlet NSComboBox *interfaceTypeComboBox;

@property (weak) IBOutlet NSComboBox *cmdTypeComboBox;

@property (weak) IBOutlet NSTextField *connectPrinterInfoTextField;

@property (weak) IBOutlet NSButton *sendDataButton;

@property (weak) IBOutlet NSButton *connectButton;

@property (weak) IBOutlet NSTableView *tableView;

@property (nonatomic, assign) HCmdType cmdType;

@property (nonatomic, assign) HInterfaceType interfaceType;

@property (nonatomic, strong) id<RYAccessory> printer;

@property (nonatomic, assign) BOOL connected;

@property (nonatomic, strong) id<HCmdSampleGenerator> sampleGenerator;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.interfaceType = HInterfaceTypeBluetooth;
    self.cmdType = HCmdTypeNomal;
    self.interfaceTypeComboBox.usesDataSource = false;
    [self.interfaceTypeComboBox addItemsWithObjectValues:@[@"Bluetooth", @"USB"]];
    [self.interfaceTypeComboBox selectItemAtIndex:0];
    [self.cmdTypeComboBox addItemsWithObjectValues:@[@"便携机", @"A4"]];
    [self.cmdTypeComboBox selectItemAtIndex:0];
    self.tableView.headerView.frame = CGRectZero;
}

- (IBAction)interfaceTypeComboxAction:(NSComboBox *)sender {
    
    switch (sender.indexOfSelectedItem) {
        case 0:
            if (self.interfaceType != HInterfaceTypeBluetooth) {
                [self disconnect];
                self.interfaceType = HInterfaceTypeBluetooth;
            }
            break;
        case 1:
            if (self.interfaceType != HInterfaceTypeUSB) {
                [self disconnect];
                self.interfaceType = HInterfaceTypeUSB;
            }
            break;
        default:
            break;
    }
}

- (IBAction)cmdTypeComboBoxAction:(NSComboBox *)sender {
    
    switch (sender.indexOfSelectedItem) {
        case 0:
            if (self.cmdType == HCmdTypeNomal) {
                return;
            }
            self.cmdType = HCmdTypeNomal;
            break;
        case 1:
            if (self.cmdType == HCmdTypeA4) {
                return;
            }
            self.cmdType = HCmdTypeA4;
            break;
        default:
            break;
    }
    if (self.printer) {
        switch (self.cmdType) {
            case HCmdTypeNomal:
                self.sampleGenerator = [[HPoooliCmdSampleGenerator alloc] initWith:self.printer target:self];
                break;
            case HCmdTypeA4:
                self.sampleGenerator = [[MTCmdSampleGenerator alloc] initWith:self.printer target:self];
                break;
            default:
                break;
        }
        [self.tableView reloadData];
    }
}

- (IBAction)sendDataAction:(NSButton *)sender {
    
    NSInteger row = self.tableView.selectedRow;
    NSArray<HSampleModel *> *models = self.sampleGenerator.sampleList;
    if (self.sampleGenerator && row < models.count) {
        if ([self.sampleGenerator respondsToSelector:models[row].selector]) {
            [self.sampleGenerator performSelector:models[row].selector];
        }
    }
}

- (void)disconnect {
    
    [self.printer disconnect];
    self.printer = nil;
    self.connected = false;
    self.sampleGenerator = nil;
    [self.tableView reloadData];
    self.sendDataButton.enabled = false;
}

- (void)didConnectPrinter:(id<RYAccessory>)printer {
    
    self.connected = true;
    self.printer = printer;
    self.connectPrinterInfoTextField.stringValue = [NSString stringWithFormat:@"连接机型: %@", self.printer.name];
    __weak typeof(self) weakSelf = self;
    self.printer.closedBlock = ^{
        NSLog(@"连接被断开");
        [weakSelf showMessage:[NSString stringWithFormat:@"打印机: %@ => 连接被断开", weakSelf.printer.name]];
        weakSelf.printer = nil;
        weakSelf.connected = false;
        weakSelf.sampleGenerator = nil;
        [weakSelf.tableView reloadData];
        weakSelf.sendDataButton.enabled = false;
    };
    switch (self.cmdType) {
        case HCmdTypeNomal:
            self.sampleGenerator = [[HPoooliCmdSampleGenerator alloc] initWith:self.printer target:self];
            break;
        case HCmdTypeA4:
            self.sampleGenerator = [[MTCmdSampleGenerator alloc] initWith:self.printer target:self];
            break;
        default:
            break;
    }
    [self.tableView reloadData];
}

- (void)showMessage:(NSString *)msg {
    
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"确定"];
    [alert setMessageText:@"提示"];
    [alert setInformativeText:msg];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:[self.view window] completionHandler:nil];
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"scan.to.connect"]) {
        HConnectViewController *destination = (HConnectViewController *)segue.destinationController;
        destination.interfaceType = self.interfaceType;
        __weak typeof(self) weakSelf = self;
        destination.connectBlock = ^(id _Nonnull printer) {
            [weakSelf didConnectPrinter:printer];
        };
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSStoryboardSegueIdentifier)identifier sender:(id)sender {
    
    if (self.connected) {
        [self disconnect];
        return false;
    }else {
        return true;
    }
}

- (void)setConnected:(BOOL)connected {
    
    _connected = connected;
    [self.connectButton setTitle:connected ? @"断开连接" : @"连接"];
    if (!self.connected) {
        self.connectPrinterInfoTextField.stringValue = @"连接机型: 未连接";
    }
}

#pragma mark --NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    cell.textField.stringValue = self.sampleGenerator.sampleList[row].title;
    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    
    self.sendDataButton.enabled = self.tableView.selectedRow != -1;
}

#pragma mark --NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    
    if (!self.sampleGenerator) {
        return 0;
    }
    return self.sampleGenerator.sampleList.count;
}

@end
