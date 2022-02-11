//
//  HTLog.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/5.
//

import UIKit
import Firebase

class HTLog: NSObject {
    class func log(_ items: Any..., separator: String = " ") {
        #if DEBUG
            print(items)
        #endif
    }
    
    class func m(_ country: String) {
        HTLog.log("[LOG] log: 用户出生地 m: \(country)")
        Analytics.setUserProperty(country, forName: "m")
    }
    
    class func one() {
        HTLog.log("[LOG] log: one")
        Analytics.logEvent("one", parameters: nil)
    }
    
    class func turn_c() {
        HTLog.log("[LOG] log: turn_c 冷启动")
        Analytics.logEvent("turn_c", parameters: nil)
    }
    
    class func turn_h() {
        HTLog.log("[LOG] log: turn_h 热启动")
        Analytics.logEvent("turn_h", parameters: nil)
    }
    
    class func textpage() {
        HTLog.log("[LOG] log: textpage 首页展示次数，每次首页展示都打")
        Analytics.logEvent("textpage", parameters: nil)
    }
    
    class func back() {
        HTLog.log("[LOG] log: back 触发退出功能的操作")
        Analytics.logEvent("back", parameters: nil)
    }
    
    class func language_list() {
        HTLog.log("[LOG] log: language_list 进入语言选择列表")
        Analytics.logEvent("language_list", parameters: nil)
    }
    
    class func textpage_t1() {
        HTLog.log("[LOG] log: textpage_t1 首页文本输入区域，进入文本翻译界面")
        Analytics.logEvent("textpage_t1", parameters: nil)
    }
    
    class func textpage_t2() {
        HTLog.log("[LOG] log: textpage_t2 文本翻译界面点击翻译按钮")
        Analytics.logEvent("textpage_t2", parameters: nil)
    }
    
    class func textpage_success(type: String) {
        HTLog.log("[LOG] log: textpage_success smart: \(type) 文本翻译成功")
        Analytics.logEvent("textpage_success", parameters: ["smart": type])
    }
    
    class func textpage_o() {
        HTLog.log("[LOG] log: textpage_o 首页点击 ocr 按钮")
        Analytics.logEvent("textpage_o", parameters: nil)
    }
    
    class func textpage_p0() {
        HTLog.log("[LOG] log: textpage_p0 在 ocr 功能中弹出相机权限")
        Analytics.logEvent("textpage_p0", parameters: nil)
    }
    
    class func textpage_p1() {
        HTLog.log("[LOG] log: textpage_p1 在 ocr 功能中弹出相机权限，同意")
        Analytics.logEvent("textpage_p1", parameters: nil)
    }
    
    class func o_click() {
        HTLog.log("[LOG] log: o_click 在 ocr 中点击拍照按钮")
        Analytics.logEvent("o_click", parameters: nil)
    }
    
    class func o_success1() {
        HTLog.log("[LOG] log: o_success1 拍照后，识别文案成功")
        Analytics.logEvent("o_success1", parameters: nil)
    }
    
    class func o_success2(type: String) {
        HTLog.log("[LOG] log: o_success2 smart: \(type) 识别文案成功后，翻译成功")
        Analytics.logEvent("o_success2", parameters: ["smart": type])
    }
    
    class func all_0() {
        HTLog.log("[LOG] log: all_0 开始翻译")
        Analytics.logEvent("all_0", parameters: nil)
    }
    
    class func all_1_sa() {
        HTLog.log("[LOG] log: all_1_sa 翻译语言和识别语言相同，翻译成功")
        Analytics.logEvent("all_1_sa", parameters: nil)
    }
    
    class func all_1_off(value: String) {
        HTLog.log("[LOG] log: all_1_off count: \(value) 离线翻译成功")
        Analytics.logEvent("all_1_off", parameters: ["count": value])
    }
    
    class func all_1_bi(value: String) {
        HTLog.log("[LOG] log: all_1_bi count: \(value) 网页翻译成功")
        Analytics.logEvent("all_1_bi", parameters: ["count": value])
    }
    
    class func all_use(type: String) {
        HTLog.log("[LOG] log: all_use count: \(type) 使用翻译功能")
        Analytics.logEvent("all_use", parameters: ["count": type])
    }
    
    class func root_1page(){
        HTLog.log("[LOG] log: 1page 首页展示")
        Analytics.logEvent("1page", parameters: nil)
    }
    
    class func root_1page_ba(){
        HTLog.log("[LOG] log: 1page_ba 返回首页")
        Analytics.logEvent("1page_ba", parameters: nil)
    }
    
    class func root_1page_1(){
        HTLog.log("[LOG] log: 1page_1 首页点击翻译")
        Analytics.logEvent("1page_1", parameters: nil)
    }
    
    class func root_1page_2(){
        HTLog.log("[LOG] log: 1page_2 首页点击VPN")
        Analytics.logEvent("1page_2", parameters: nil)
    }
    
    class func vpn_vpage(){
        HTLog.log("[LOG] log: vpage VPN首页展示")
        Analytics.logEvent("vpage", parameters: nil)
    }
    
    class func vpn_vuse1(){
        HTLog.log("[LOG] log: vuse1 触发连接")
        Analytics.logEvent("vuse1", parameters: nil)
    }
    
    class func vpn_vuse2(){
        HTLog.log("[LOG] log: vuse2 触发连接，测速成功")
        Analytics.logEvent("vuse2", parameters: nil)
    }
    
    class func vpn_vuse3(country: String) {
        HTLog.log("[LOG] log: vuse3 smart: \(country) 连接成功")
        Analytics.logEvent("vuse3", parameters: ["smart": country])
    }
    
    class func vpn_vdisuse(){
        HTLog.log("[LOG] log: vdisuse 断开连接")
        Analytics.logEvent("vdisuse", parameters: nil)
    }
    
    class func vpn_vpermis(){
        HTLog.log("[LOG] log: vpermis 弹出VPN权限")
        Analytics.logEvent("vpermis", parameters: nil)
    }
    
    class func vpn_vpermis1(){
        HTLog.log("[LOG] log: vpermis1 同意VPN权限")
        Analytics.logEvent("vpermis1", parameters: nil)
    }
    
}
