//
//  HTSetViewController.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/5.
//

import UIKit

class HTSetViewController: UIViewController {
    
    lazy var topV: HTTopView = {
        let v = HTTopView.loadFromXib()
        v.titleLab.text = "Setting"
        v.leftBtn.setImage(UIImage(named: "back_dark"), for: .normal)
        v.leftActionBlock = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        return v
    }()
    
    lazy var tableView: UITableView = {
        let tableV = UITableView(frame: .zero, style: .grouped)
        tableV.delegate = self
        tableV.dataSource = self
        tableV.backgroundColor = .clear
        tableV.separatorStyle = .none
        tableV.rowHeight = 60
        tableV.estimatedRowHeight = 60
        tableV.register(UINib(nibName: String(describing: HTSetTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: HTSetTableViewCell.self))
        return tableV
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ColorFromRGB(0xf5f7fc)
        view.addSubview(topV)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(topV.snp.bottom)
        }
        
    }

}

extension HTSetViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: HTSetTableViewCell.self)) as! HTSetTableViewCell
        cell.selectionStyle = .none
        
        switch indexPath.row {
        case 0:
            cell.leftImgV.image = UIImage(named: "icon_rate")
            cell.textLab.text = "Rate us"
        case 1:
            cell.leftImgV.image = UIImage(named: "icon_share")
            cell.textLab.text = "Share"
        case 2:
            cell.leftImgV.image = UIImage(named: "icon_terms")
            cell.textLab.text = "Terms of Service"
        case 3:
            cell.leftImgV.image = UIImage(named: "icon_privacy")
            cell.textLab.text = "Privacy Policy"
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        210
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: screen_width, height: 210))
        let imgV = UIImageView()
        imgV.image = UIImage(named: "logo_set")
        view.addSubview(imgV)
        imgV.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            UIApplication.shared.open(URL(string: "https://apps.apple.com/us/app/id1603792739")!, options: [:], completionHandler: nil)
        case 1:
            let params = [
                UIImage(named: "logo")!,
                URL(string: "https://apps.apple.com/us/app/id1603792739")!
            ] as [Any]
            let activity = UIActivityViewController(activityItems: params, applicationActivities: nil)
            present(activity, animated: true, completion: nil)
        case 2:
            let vc = HTLabelViewController()
            vc.type = .at
            self.navigationController?.pushViewController(vc, animated: true)
        case 3:
            let vc = HTLabelViewController()
            vc.type = .tp
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}

