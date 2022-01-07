//
//  HTLabelViewController.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/5.
//

import UIKit

enum HTLabelType {
    case at, tp
}

class HTLabelViewController: UIViewController {
    
    var type: HTLabelType = .at
    
    lazy var topV: HTTopView = {
        let v = HTTopView.loadFromXib()
        v.titleLab.text = type == .at ? "Terms of Service" : "Privacy Policy"
        v.leftBtn.setImage(UIImage(named: "back_dark"), for: .normal)
        v.leftActionBlock = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        return v
    }()
    
    lazy var backV: UIScrollView = {
        let backV = UIScrollView()
        backV.contentSize = CGSize(width: screen_width, height: CGFloat(MAXFLOAT))
        backV.backgroundColor = .clear
        self.view.addSubview(backV)
        backV.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(topV.snp.bottom)
        }
        return backV
    }()
    
    lazy var textLabel: UILabel = {
        let lab = UILabel(frame: CGRect(x: 20, y: 18, width: screen_width - 40, height: screen_height - topV.frame.size.height - safeBottom_height - 18))
        lab.numberOfLines = 0
        lab.lineBreakMode = .byWordWrapping
        lab.font = UIFont.systemFont(ofSize: 14)
        lab.textColor = UIColor.ColorFromRGB(0x1E2C38)
        backV.addSubview(lab)
        return lab
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(topV)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.addText()
        }

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    func addText() {
        self.textLabel.text = type == .at ? HTLabelText.at : HTLabelText.pp
        let height = self.textLabel.sizeThatFits(CGSize(width: screen_width - 40, height: CGFloat(MAXFRAG))).height
        self.textLabel.frame = CGRect(x: 20, y: 10, width: screen_width - 40, height: height)
        self.backV.contentSize = CGSize(width: screen_width, height: height + 40)
    }
    
}

enum HTLabelText {
    static let at = "- Please read these terms carefully before accessing or using any of our solution applications.\n- We provide the application in accordance with the following terms of use. If you do not accept these terms of use, please do not use the application. If you use the application, it means you accept the terms of use.\n\n- 1. Use of the application\n- 1.1 Using this application means that you agree to the processing of data in accordance with our privacy policy. Our privacy policy complies with the General Data Protection Regulation.\n- 1.2 You agree to use this application only for (a) the purposes permitted by these terms of use and (b) applicable laws, regulations or generally accepted practices or guidelines in jurisdictions. You agree to comply with all local laws and regulations regarding downloading, installing and/or using the application.\n- 1.3 You agree that our solution is not responsible for any content accessed from third-party applications or websites. You agree to be solely responsible for the use of the application (our solution is not responsible for you or a third party).\n- 1.4 You recognize that the application can communicate with our server at any time to check for application updates, such as bug fixes, patches, enhancements, absent plug-ins and new versions. When you install the app, you automatically agree to these requests and the updates you receive.\n- 1.5 You agree that we may suspend (permanently or temporarily) providing applications (or any application resources) to you or AOS users without prior notice. You agree that if we prohibit access to the application, you may not be able to access the application or certain application features.\n- 1.6 You may not distribute, publish or send through application: (1) Any spam, including unsolicited advertisements, invitations, commercial information, advertisements or any type of promotional information; (2) Chain mail; (3) Same or basic Multiple copies of similar information; 4) Blank information; 5) Messages that do not contain substantive content; 6) Large messages or files that destroy servers, accounts, newsgroups or chat services; 7) Anything classified as \"phishing \"s mail.\n\n- 2. Intellectual Property\n- 2.1 This application and all its content, such as the user interface, editing and layout of website content, as well as all text, graphics, images, sounds, videos, data, applications, etc., belong to us, our licensors or content providers , And is protected by copyright law and other intellectual property laws. Unless expressly permitted by these Terms of Use, copying or redistributing such content is prohibited.\n- 2.2 We grant you a personal, non-exclusive and non-transferable license to access and use our apps. Unless expressly agreed in writing, you may not download, reverse engineer, decompile, disassemble, or modify any part of this document. Without our written consent, it may not be copied, sold, resealed or otherwise used in any commercial FIM. Without our prior written consent, you may not link, create frames, or use frame technology to attach trademarks, logos, or own other information about the application, including images, text, page layouts, or forms. Unauthorized use of the application will immediately interrupt the limited license granted by our solution.\n\n- 3. No liability guarantee or limitation\n- 3.1 Our solution cannot ensure that the application, its function or content will not be interrupted or incorrect, nor can it ensure that defects are corrected. Our solution does not declare or guarantee the accuracy or applicability of any benefits, announcements, or third-party content related to the application. The application is provided \"in the country where it was found\". You agree to use the application at your own risk.\n- 3.2 Our solution is not responsible for any type of damage caused by your use or inability to use the application. Our liability for any claims you may bring to us is limited to the amount actually paid by you.\n\n- 4. Revision\n- 4.1 These terms of use can be updated at any time. We will notify you of any changes to our terms of use when we publish new terms of use.\n- It is recommended to review these terms of use regularly to see changes."
    
    static let pp = "- Your privacy is important to our application. Sometimes we need information to provide the required services, this privacy statement applies to our applications and products.\n\n- What information do we use and how we use it:\n- Read phone status and identity: This permission allows our application to recognize incoming connections and switch between the user system interface and the connection interface.\n- Look for an account on a device where the app can’t recognize or save any app’s account information. We only know whether the user has a apple account linked to the device, which helps us confirm the status of apple services and provide users with appropriate ways to download and update applications.\n- Read the apple service configuration: this information is used to obtain the advertising identifier. We use this anonymous identifier to provide users with better advertising services.\n- Change network connection: This permission is used to configure and notify the toolbar about changing network connection information.\n- Connect and disconnect Wi-Fi: This permission is used to configure and notify the toolbar to connect and disconnect from Wi-Fi networks.\n- Full access to the network: This permission is used to access the device's network to perform certain functions, including receiving notifications of launcher updates.\n- Application storage space measurement: This permission is used to obtain the amount of space used by the application.\n- Disclosure of user personal data: All applications require permission in the following areas, including audio/video files, images, microphones, and external storage of the device. The stored information is not used for data exchange and does not violate any privacy policy.\n- The device uses the Android or IOS browser and operating system to automatically store some data, including device identifiers. All these boundaries are collected to help us improve the services provided through the app. This information is not provided to any other sellers, nor is it public. All included applications do not need to access this location.\n- In order to provide you with one of the best advanced features, the app contains. To purchase them, you must provide your contact information and account details. This information is stored to avoid online fraud or any illegal activities, but we will not sell it to any government or other companies.\n- Data collection: All data is collected from verified sources listed in the application statement.\n- Public voices are collected from public sources that do not violate apple’s conditions.\n- As far as we know, the entire content of this application is in the public domain, but if such content has copyright issues, please contact us through the email identifier we provide, and we will replace or omit all content.\n\n- How we protect your data:\n- We have adopted commercially reasonable technical and organizational measures to protect users' personal data from accidental loss, misuse, and unauthorized access, disclosure, alteration and destruction. However, it should be remembered that although we are taking reasonable measures to protect user information, any application, website, Internet transmission, computer system, or wireless connection is completely secure. Children's privacy We make every effort to protect children's privacy. We do not knowingly collect personal data from children under 13 years of age. Changes to our privacy policy Our application may change this privacy policy from time to time. Any changes will be reflected here. The new version will be explained in the upper part of this privacy policy on the day of its premiere, so please check it regularly.\n- We recommend that you review this privacy policy weekly or monthly to understand any changes that may occur"
}

