//
//  TitleImageTableViewCell.swift
//  SurfingGo
//
//  Created by 野澤 通弘 on 2017/10/25.
//  Copyright © 2017年 ikaika software. All rights reserved.
//
import UIKit
import Eureka

final class TitleImageTableViewCell: Cell<TitleImage>, CellType, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var imageLabel: UIImageView!
    @IBOutlet weak var titleOfImageLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    lazy public var picker: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private var pickerInputRow: TitleImagePickerRow? { return row as? TitleImagePickerRow }

    public required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func setup() {
        super.setup()
        accessoryType = .none
        editingAccessoryType = .none
        picker.delegate = self
        picker.dataSource = self
    }
    
    deinit {
        picker.delegate = nil
        picker.dataSource = nil
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func update() {
        super.update()
        
        guard let value = row.value else { return }

        self.imageLabel.image = value.image
        self.titleOfImageLabel.text = value.titleOfImage

        selectionStyle = row.isDisabled ? .none : .default

        textLabel?.textColor = row.isDisabled ? .gray : .black
        if row.isHighlighted {
            textLabel?.textColor = tintColor
        }
        
        picker.reloadAllComponents()
        if let selectedValue = pickerInputRow?.value, let index = pickerInputRow?.options.index(of: selectedValue) {
            picker.selectRow(index, inComponent: 0, animated: true)
        }
    }
    
    open override func didSelect() {
        super.didSelect()
        row.deselect()
    }
    
    open override var inputView: UIView? {
        return picker
    }
    
    open override func cellCanBecomeFirstResponder() -> Bool {
        return canBecomeFirstResponder
    }
    
    override open var canBecomeFirstResponder: Bool {
        return !row.isDisabled
    }
    
    open func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    open func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerInputRow?.options.count ?? 0
    }
    
    open func pickerView(_ pickerView: UIPickerView, didSelectRow rowNumber: Int, inComponent component: Int) {
        if let picker = pickerInputRow, picker.options.count > rowNumber {
            picker.value = picker.options[rowNumber]
            update()
        }
    }
    open func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        return UIImageView(image: self.pickerInputRow?.options[row].image)
    }
}

final class TitleImagePickerRow: Row<TitleImageTableViewCell>, NoValueDisplayTextConformance, RowType {
    var noValueDisplayText: String?
    
    var options = [TitleImage]()

    required init(tag: String?) {
        super.init(tag: tag)
        cellProvider = CellProvider<TitleImageTableViewCell>(nibName: "TitleImageTableViewCell")
    }
}
