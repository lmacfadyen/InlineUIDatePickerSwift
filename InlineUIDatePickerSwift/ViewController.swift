//
//  ViewController.swift
//  InlineUIDatePickerSwift
//
//  Created by Lawrence F MacFadyen on 2017-07-28.
//  Copyright © 2017 Lawrence F MacFadyen. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var stackTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var dateTableHeightConstraint: NSLayoutConstraint!
    
    // The date fields that will hold the title and current date values, and the formatter
    var fields = [DateField]()
    var dateFormatter = DateFormatter()
    
    // For Date/Time validation
    var minStart = Date()
    var minEnd = Date()
    var currentStart = Date()
    
    // Supporting one time set of stackTopConstraint when view appears the first time
    var hasAppeared = false
    
    // The indexPath when the UIDatePicker is open
    var datePickerIndexPath: IndexPath?
    
    //MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createDateFields()
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        // if the locale changes while in the background, notify so we can update the date
        // format in the table view cells
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.localeChanged(_:)), name: NSLocale.currentLocaleDidChangeNotification, object: nil)
        
        tableView.delegate = self
        tableView.dataSource = self
        

        // Defined first in storyboard, so bring to front so will be over stack view. See notes
        // in tutorial because if you don't want to be flexible to accommodate modifying
        // such that map size adjusts when date pickers open, then table can just be first in
        // the storyboard.

        view.bringSubview(toFront: tableView)
        
        // Sets the date field values
        configureTimes()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reSyncTimesIfNeeded()
        tableView.reloadData()
        
        if(!hasAppeared)
        {
            // Height set to initial contentSize of table
            dateTableHeightConstraint.constant = tableView.contentSize.height
            // Lower the stack view top to bottom of initial table view and it will stay here intentionally
            // This is intentional because I want the tableView to float over the map when date picker is open.
             
            // Note: Remove this next line if you want the stack view top to stay with the tableView bottom,
            // and add one Vertical Space constraint between the tableView bottom and stackView top,
            // with a constant of 0. See tutorial for additional details.

            stackTopConstraint.constant = tableView.contentSize.height
        }
        hasAppeared = true
    }
    
    // Let's match the black navigation bar
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Notifications
    func localeChanged(_ notif: Notification) {
        // In case locale changes
        tableView.reloadData()
    }
    
    //MARK: UIDatePicker and Times
    
    // For handling return to this ViewController from another (when implemented)
    func reSyncTimesIfNeeded()
    {
        // Update times if current time has passed minStart or current Start
        let now = Date()
        let roundedStart = now.roundedToNext(interval:15)
        
        let isGreater = minStart > roundedStart
        if(isGreater)
        {
            configureTimes()
        }
    }
    
    // Set dates so start is at next 15 minute interval and end is 1 hour after start
    func configureTimes()
    {
        let now = Date()
        let roundedStart = now.roundedToNext(interval:15)
        let roundedEnd = roundedStart.addingTimeInterval(3600.0)
        
        let dateFieldStart = fields[0]
        let dateFieldEnd = fields[1]
        
        minStart = roundedStart
        currentStart = roundedStart
        minEnd = currentStart.addingTimeInterval(900.0)
        
        dateFieldStart.date = roundedStart
        dateFieldEnd.date = roundedEnd
        
    }
    

    // Change end time date field value if necessary and trigger handling of
    // the time change. In your own app you would define what is in the
    // handleTimeChange method.

    @IBAction func dateAction(_ sender: UIDatePicker) {
        
        let parentIndexPath = IndexPath(row: (datePickerIndexPath! as NSIndexPath).row - 1, section: 0)
        let dateField = fields[(parentIndexPath as NSIndexPath).row]
        dateField.date = sender.date
        let fieldCell = tableView.cellForRow(at: parentIndexPath)!
        fieldCell.detailTextLabel!.text = dateFormatter.string(from: sender.date)
        if((parentIndexPath as NSIndexPath).row == 0)
        {
            // start changed, so update min of end to be +15 minutes
            currentStart = sender.date
            minEnd = currentStart.addingTimeInterval(900.0)
            let endDateField = fields[1]
            let endDate = endDateField.date
            
            let isLessOrEqual = endDate <= currentStart
            if(isLessOrEqual)
            {
                // force end to be 15 minutes past start if it was less or equal
                fields[1].date = currentStart.addingTimeInterval(900.0)
            }
        }
        // user changed a date and validation is complete
        handleTimeChange()
    }
    
    // Get the dates and do whatever your application needs with them
    func handleTimeChange()
    {
        let dateFieldStart = fields[0].date
        let dateFieldEnd = fields[1].date
        print("Start \(dateFieldStart) End \(dateFieldEnd)")
    }
    
    // Returns the correct date field
    func dateFieldForIndexPath(indexPathSelected: IndexPath) -> DateField {
        if(datePickerIndexPath != nil) {
            if((datePickerIndexPath! as NSIndexPath).row == 2)
            {
                // If date picker is row 2, then index of dateCell matches fields indexing of 0 or 1
                return fields[(indexPathSelected as NSIndexPath).row]
            }
            else{
                
                // Date picker is startDate which means endDate cell is index 2
                if((indexPathSelected as NSIndexPath).row == 0)
                {
                    // There is a date picker, and this is cell 0, so get the 0th field
                    return fields[0]
                }
                else{
                    // There is a date picker, this is not cell 0, which means it is cell index 2
                    // so get field index 1
                    return fields[1]
                }
            }
        }
        else {
            // No date picker is open, so its a plain dateCell with index matching field index
            return fields[(indexPathSelected as NSIndexPath).row]
        }
    }
    
    func createDateFields() {
        let field1 = DateField(title: "Start Time", date: Date())
        let field2 = DateField(title: "End Time", date: Date())
        fields.append(field1)
        fields.append(field2)
        configureTimes()
    }
    
    func calculateDatePickerIndexPath(_ indexPathSelected: IndexPath) -> IndexPath {
        if datePickerIndexPath != nil && (datePickerIndexPath! as NSIndexPath).row  < (indexPathSelected as NSIndexPath).row {
            return IndexPath(row: (indexPathSelected as NSIndexPath).row, section: 0)
        } else {
            return IndexPath(row: (indexPathSelected as NSIndexPath).row + 1, section: 0)
        }
    }
    
    // Determines if the UITableView has a UIDatePicker in any of its cells.
    func hasInlineDatePicker() -> Bool {
        return datePickerIndexPath != nil
    }
    
    //Determines if the given indexPath points to a UIDatePicker cell
    func indexPathHasPicker(_ indexPath: IndexPath) -> Bool {
        return hasInlineDatePicker() && (datePickerIndexPath as NSIndexPath?)?.row == (indexPath as NSIndexPath).row
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.beginUpdates()
        if datePickerIndexPath != nil && (datePickerIndexPath! as NSIndexPath).row - 1 == (indexPath as NSIndexPath).row {
            tableView.deleteRows(at: [datePickerIndexPath!], with: .fade)
            datePickerIndexPath = nil
        } else {
            if datePickerIndexPath != nil {
                tableView.deleteRows(at: [datePickerIndexPath!], with: .fade)
            }
            datePickerIndexPath = calculateDatePickerIndexPath(indexPath)
            tableView.insertRows(at: [datePickerIndexPath!], with: .fade)
        }
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.endUpdates()
        // Required in this case for correct contentSize
        tableView.reloadData()
        
        // Set the height of tableView to match its content size height
        // Constraint is an easy way to do it versus adding up row heights
        dateTableHeightConstraint.constant = tableView.contentSize.height
    }
    
    // Estimate the rowHeight
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        var rowHeight = 44
        if datePickerIndexPath != nil && datePickerIndexPath!.row == indexPath.row {
            let cell = tableView.dequeueReusableCell(withIdentifier: "datePickerCell")!
            rowHeight = Int(Double(cell.frame.height))
        }
        return CGFloat(rowHeight)
    }
    
    // Automatic height or date picker height from storyboard
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var rowHeight = UITableViewAutomaticDimension
        if datePickerIndexPath != nil && datePickerIndexPath!.row == indexPath.row {
            let cell = tableView.dequeueReusableCell(withIdentifier: "datePickerCell")!
            rowHeight = cell.frame.height
        }
        return rowHeight
    }
    
    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = fields.count
        if datePickerIndexPath != nil {
            // Add one row to the field count since date picker is open
            rows += 1
        }
        return rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        if datePickerIndexPath != nil && (datePickerIndexPath! as NSIndexPath).row == (indexPath as NSIndexPath).row
        {
            // Date picker open and this cell index is the datePickerIndexPath
            cell = tableView.dequeueReusableCell(withIdentifier: "datePickerCell")!
            let datePicker = cell.viewWithTag(99) as! UIDatePicker
            // Since we have a date picker, the index of dateField is one less
            let row = (indexPath as NSIndexPath).row - 1
            let dateField = fields[row]
            datePicker.setDate(dateField.date as Date, animated: true)
            if(row==0)
            {
                // Date picker is for start date
                datePicker.minimumDate = minStart
                
            }
            else
            {
                // Date picker is for end date so configure time interval as +15 minutes
                datePicker.minimumDate = currentStart.addingTimeInterval(900.0)
            }
        }
        else {
            // This cell isn't a date picker, so it is a dateCell
            cell = tableView.dequeueReusableCell(withIdentifier: "dateCell")!
            let dateField = dateFieldForIndexPath(indexPathSelected: indexPath)
            cell.textLabel?.text = dateField.title
            cell.detailTextLabel?.text = dateFormatter.string(from: dateField.date as Date)
        }
        
        // Set background color of cell
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.black
        cell.selectedBackgroundView = backgroundView
        
        return cell
    }

}


// Mark: DateField
class DateField {
    let title: String
    var date: Date = Date()
    init(title: String, date: Date) {
        self.title = title
        self.date = date
    }
}

// Mark: Date Extensions
extension Date{
    // Round date up to next interval
    func roundedToNext(interval:Int) -> Date{
        let calendar = Calendar.current
        var nextDiff = interval - calendar.component(.minute, from: self) % interval
        if(nextDiff == interval)
        {
            nextDiff = 0
        }
        let roundedDate = calendar.date(byAdding: .minute, value: nextDiff, to: self) ?? Date()
        return roundedDate
    }
    
}

