//
//  ViewController.swift
//  Commotion
//
//  Created by Eric Larson on 9/6/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//

import UIKit
import CoreMotion

class ModulAViewController: UITableViewController {
    
    //MARK:- Interface Builder
    @IBOutlet weak var stepsSlider: UISlider!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var isWalking: UILabel!
    @IBOutlet weak var dailyGoalLabel: UILabel!
    @IBOutlet weak var todayStepCountLabel: UILabel!
    
    //MARK: class variables
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    let motion = CMMotionManager()
    var totalSteps: Float = 0.0 {
        willSet(newtotalSteps){
            DispatchQueue.main.async{
                self.stepsLabel.text = "Steps: \(newtotalSteps)"
                self.getStepCountForToday(completion: { (steps) in
                    DispatchQueue.main.async {self.todayStepCountLabel.text = "You walked total \(steps) steps today"
                        self.stepsSlider.value = Float(steps)
                    }
                })
            }
        }
    }
    var stepCountForYesterday = 0
    
    //MARK: View Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.totalSteps = 0.0
        self.startActivityMonitoring()
        self.startPedometerMonitoring()
        self.startMotionUpdates()
        
        self.getStepCountForToday { (steps) in
            DispatchQueue.main.async {
                self.todayStepCountLabel.text = "You walked total \(steps) steps today"
                self.stepsSlider.value = Float(steps)
            }
        }
        
        self.getStepCountForYesterday { (steps) in
            DispatchQueue.main.async {
                self.stepCountForYesterday = steps
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        //fetch the daily goal from persistance storage
        if let stepGoal = UserDefaults.standard.value(forKey: "StepGoal") {
            let steps = stepGoal as! Int
            self.dailyGoalLabel.text = "Your daily goal is \(steps) steps"
            self.stepsSlider.maximumValue  = Float(steps)
        } else {
            UserDefaults.standard.set(1000, forKey: "StepGoal")
            self.dailyGoalLabel.text = "Your daily goal is \(1000) steps"
            self.stepsSlider.maximumValue  = Float(1000)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: Raw Motion Functions
    func startMotionUpdates(){
        // some internal inconsistency here: we need to ask the device manager for device 
        
        // TODO: should we be doing this from the MAIN queue? You will need to fix that!!!....
        if self.motion.isDeviceMotionAvailable{
            self.motion.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: handleMotion)
        }
    }
    
    func handleMotion(_ motionData:CMDeviceMotion?, error:Error?){
        if let gravity = motionData?.gravity {
            let rotation = atan2(gravity.x, gravity.y) - Double.pi
            self.isWalking.transform = CGAffineTransform(rotationAngle: CGFloat(rotation))
        }
    }
    
    // MARK: Activity Functions
    func startActivityMonitoring(){
        // is activity is available
        if CMMotionActivityManager.isActivityAvailable(){
            // update from this queue (should we use the MAIN queue here??.... )
            self.activityManager.startActivityUpdates(to: OperationQueue.main, withHandler: self.handleActivity)
        }
        
    }
    
    func handleActivity(_ activity:CMMotionActivity?)->Void{
        // unwrap the activity and disp
        if let unwrappedActivity = activity {
            DispatchQueue.main.async{
                print(unwrappedActivity.walking)
                if unwrappedActivity.stationary == true {
                    self.isWalking.text = "Status - Still"
                } else if unwrappedActivity.walking == true {
                    self.isWalking.text = "Status - Walking"
                } else if unwrappedActivity.cycling == true {
                    self.isWalking.text = "Status - Cycling"
                } else if unwrappedActivity.automotive == true {
                    self.isWalking.text = "Status - Driving"
                } else if unwrappedActivity.running == true {
                    self.isWalking.text = "Status - Running"
                } else if unwrappedActivity.unknown == true {
                    self.isWalking.text = "Status - Unknown"
                } else {
                    self.isWalking.text = "Status - Unknown"
                }
            }
        }
    }
    
    // MARK: Pedometer Functions
    func startPedometerMonitoring(){
        //separate out the handler for better readability
        if CMPedometer.isStepCountingAvailable(){
            pedometer.startUpdates(from: Date(),withHandler: self.handlePedometer )
        }
    }
    
    //ped handler
    func handlePedometer(_ pedData:CMPedometerData?, error:Error?){
        if let steps = pedData?.numberOfSteps {
            self.totalSteps = steps.floatValue
        }
    }

    //Today total step count
    func getStepCountForToday(completion: @escaping (Int) -> ()) {
        let midnightDate = self.getMidnightDate(date: Date())
        
        pedometer.queryPedometerData(from: midnightDate, to: Date()) { (data, error) in
            guard let activityData = data else {
                print("There was error getting data!")
                print(error!)
                return
            }
            completion(activityData.numberOfSteps.intValue)
        }
    }
    
    func getStepCountForYesterday(completion: @escaping (Int) -> ()) {
        let today = self.getMidnightDate(date: Date())
        let yesterday = self.getMidnightDate(date: self.getYesterdayDate())
        
        pedometer.queryPedometerData(from: yesterday , to: today) { (data, error) in
            guard let activityData = data else {
                print("There was error getting data!")
                print(error!)
                return
            }
            completion(activityData.numberOfSteps.intValue)
        }
    }
    
    func getMidnightDate(date: Date) -> Date {
        var calender = Calendar.current
        var component = calender.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        component.hour = 0
        component.minute = 0
        component.second = 0
        calender.timeZone = TimeZone.current
        
        return calender.date(from: component)!
    }
    
    func getYesterdayDate() -> Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    }
    
}


//MARK:- TableView Datasource Method
extension ModulAViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    // if green reached goal and if red did not reach goal
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = "Step Count: \(self.stepCountForYesterday)"
        if let stepGoal = UserDefaults.standard.value(forKey: "StepGoal") {
            let steps = stepGoal as! Int
            if self.stepCountForYesterday >= steps {
                cell.contentView.backgroundColor = UIColor.green
                cell.detailTextLabel?.text = "You reached your daily goal!"
            } else {
                cell.contentView.backgroundColor = UIColor.red
                cell.detailTextLabel?.text = "You have not reached your daily goal!"
            }
        }
        return cell
    }
}
