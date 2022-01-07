//
//  HTLanguageViewController.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/5.
//

import UIKit
import ZKProgressHUD

class HTLanguageViewController: UIViewController {
    
    var isSource: Bool = true
    var isFromText: Bool = true
    
    lazy var topV: HTTopView = {
        let v = HTTopView.loadFromXib()
        v.titleLab.text = "Language"
        v.leftBtn.setImage(UIImage(named: "back_dark"), for: .normal)
        v.leftActionBlock = { [weak self] in
            HTLog.back()
            self?.navigationController?.popViewController(animated: true)
        }
        return v
    }()
    
    lazy var tableView: UITableView = {
        let tableV = UITableView(frame: .zero, style: .grouped)
        tableV.delegate = self
        tableV.dataSource = self
        tableV.separatorStyle = .none
        tableV.backgroundColor = .white
        tableV.rowHeight = 48
        tableV.estimatedRowHeight = 48
        tableV.register(UINib(nibName: String(describing: HTLanguageTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: HTLanguageTableViewCell.self))
        return tableV
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        view.addSubview(topV)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(topV.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        HTLog.language_list()
    }
    
}

extension HTLanguageViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : HTTransUtil.shared.languageList.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: HTLanguageTableViewCell.self)) as! HTLanguageTableViewCell
        cell.selectionStyle = .none
        if indexPath.section == 0 {
            cell.selectImgV.isHighlighted = true
            var string: String?
            if isFromText {
                if isSource {
                    string = UserDefaults.standard.value(forKey: LaguageString.textSourceTitle) as? String
                } else {
                    string = UserDefaults.standard.value(forKey: LaguageString.textTargetTitle) as? String
                }
            } else {
                if isSource {
                    string = UserDefaults.standard.value(forKey: LaguageString.ocrSourceTitle) as? String
                } else {
                    string = UserDefaults.standard.value(forKey: LaguageString.ocrTargetTitle) as? String
                }
            }
            cell.textLab.text = string == "Auto" ? "Auto Detect" : string
            cell.textLab.textColor = UIColor.ColorFromRGB(0x19bbc6)
        } else {
            cell.textLab.textColor = UIColor.ColorFromRGB(0x363C40)
            cell.selectImgV.isHighlighted = false
            cell.textLab.text = indexPath.row == 0 ? "Auto Detect" : Locale.current.localizedString(forLanguageCode: HTTransUtil.shared.languageList[indexPath.row - 1].rawValue)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0.0001 : 38
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return UIView(frame: CGRect(x: 0, y: 0, width: screen_width, height: 0.0001))
        } else {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: screen_width, height: 38))
            view.backgroundColor = .clear
            let label = UILabel(frame: CGRect(x: 16, y: 0, width: screen_width, height: 30))
            view.addSubview(label)
            label.text = "ALL LANGUAGES"
            label.font = UIFont.systemFont(ofSize: 12)
            label.textColor = UIColor.ColorFromRGB(0x878e8f)
            return view
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 0.0001 : safeBottom_height + 10
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section != 0 {
            var indexKey: String = ""
            var stringKey: String = ""
            if isFromText {
                if isSource {
                    indexKey = LaguageString.textSourceIndex
                    stringKey = LaguageString.textSourceTitle
                } else {
                    indexKey = LaguageString.textTargetIndex
                    stringKey = LaguageString.textTargetTitle
                }
            } else {
                if isSource {
                    indexKey = LaguageString.ocrSourceIndex
                    stringKey = LaguageString.ocrSourceTitle
                } else {
                    indexKey = LaguageString.ocrTargetIndex
                    stringKey = LaguageString.ocrTargetTitle
                }
            }
            
            let index = UserDefaults.standard.value(forKey: indexKey) as! Int
            if index == indexPath.row - 1 {
                return
            }
            
            if indexPath.row == 0 {
                UserDefaults.standard.set("Auto", forKey: stringKey)
                UserDefaults.standard.setValue(indexPath.row - 1, forKey: indexKey)
            } else {
                UserDefaults.standard.setValue(Locale.current.localizedString(forLanguageCode: HTTransUtil.shared.languageList[indexPath.row - 1].rawValue), forKey: stringKey)
                UserDefaults.standard.setValue(indexPath.row - 1, forKey: indexKey)
            }
            if isFromText {
                NotificationCenter.default.post(name: NSNotification.Name.Language.refreshText, object: nil)
            } else {
                NotificationCenter.default.post(name: NSNotification.Name.Language.refreshOcr, object: nil)
            }
            self.navigationController?.popViewController(animated: true)
        } else {
//            let uuid = UUID().uuidString
//            ZKProgressHUD.showMessage(uuid, autoDismissDelay: 5)
            
            
//            crashButtonTapped()
        }
    }
    
        func crashButtonTapped() {
              let numbers = [0]
              let _ = numbers[1]
          }
}

