//
//  StatisticsController.swift
//  oliveiras-bot
//
//  Created by Marina Miranda Aranha on 07/05/20.
//  Copyright © 2020 Oliveiras. All rights reserved.
//

import UIKit
import Charts

class StatisticsTableViewController: UITableViewController {

    // Cell identifier
    let cellId = "VisaoGeralTableViewCell"
    
    // LOCATION SECTION
    @IBOutlet weak var countryIcon: UIImageView!
    @IBOutlet weak var disclosureLabel: UILabel!
    
    // GRAPHIC SECTION
    @IBOutlet weak var segmented: UISegmentedControl!
    @IBOutlet weak var chartView: LineChartView!
    
    enum ChartType {
        case confirmed
        case recovered
        case deaths
    }
    
    var chartType: ChartType = .confirmed
    var chartColor = UIColor()
    
    let headerHight: CGFloat = 55
    
    // VISAO GERAL SECTION
    let cellId = "VisaoGeralTableViewCell"
    
    // coronaStatistics[0] - Confirmed
    // coronaStatistics[1] - Recovered
    // coronaStatistics[2] - Active
    // coronaStatistics[3] - Deaths
    var coronaStatistics: [Int]!
    
    // SELECTED LOCATION
    var selectedLocation: String!
    
    var country = Country(name: "Mundo", image: UIImage(named: "world")!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.title = "Estatísticas"
        
        //Set segment control properties
        segmented.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: UIControl.State.selected)
        segmented.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: UIControl.State.normal)
        
        plotGraphic()
        
        // Registering cell
        self.tableView.register(UINib.init(nibName: cellId, bundle: nil), forCellReuseIdentifier: cellId)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // TODO: Get selected location based
        // on user selection
        self.selectedLocation = "Mundo"
        
        getCasesNumber(location: selectedLocation)
        //Set Charts Properties
        setChartProperties()
    }
    
    func setChartProperties() {
        var index = segmented.selectedSegmentIndex
        let countryNameUS = Countries().countryBRtoUS(countryNameBR: country.name)
        let countryNameSlug = Countries().countryToSlugAPI(countryNameUS: countryNameUS)
        
        //GLOBAL STATISTICS
        if country.name == "Mundo" {
            if segmented.numberOfSegments == 3 {
                segmented.removeSegment(at: 1, animated: true)
                segmented.selectedSegmentIndex = 0
                index = segmented.selectedSegmentIndex
            }
            switch index {
            case 0:
                chartType = .confirmed
                chartColor = #colorLiteral(red: 1, green: 0.6235294118, blue: 0.03921568627, alpha: 1)
                dailyGlobalCases(caseType: "confirmed")
            case 1:
                chartType = .deaths
                chartColor = #colorLiteral(red: 1, green: 0.2705882353, blue: 0.2274509804, alpha: 1)
                dailyGlobalCases(caseType: "deaths")
            default:
                chartType = .confirmed
            }
        //COUNTRY STATISTICS
        } else {
            if segmented.numberOfSegments == 2 {
                segmented.insertSegment(withTitle: "Recuperados", at: 1, animated: true)
                segmented.selectedSegmentIndex = 0
                index = segmented.selectedSegmentIndex
            }
            switch index {
            case 0:
                chartType = .confirmed
                chartColor = #colorLiteral(red: 1, green: 0.6235294118, blue: 0.03921568627, alpha: 1)
                dailyCountryCases(country: countryNameSlug, caseType: "Confirmed")
            case 1:
                chartType = .recovered
                chartColor = #colorLiteral(red: 0.1960784314, green: 0.8431372549, blue: 0.2941176471, alpha: 1)
                dailyCountryCases(country: countryNameSlug, caseType: "Recovered")
            case 2:
                chartType = .deaths
                chartColor = #colorLiteral(red: 1, green: 0.2705882353, blue: 0.2274509804, alpha: 1)
                dailyCountryCases(country: countryNameSlug, caseType: "Deaths")
            default:
                chartType = .confirmed
            }

        }
        
        
    }
    
    func plotGraphic(chartColor: UIColor, chartValues: [(x: String, y: Int)], xAxisMin: Int) {
        //Array that will display the graphic
        var chartEntry = [ChartDataEntry]()
        var days: [String] = []
        
        for i in 0..<chartValues.count {
            //Set x and y status in a data chart entry
            let xValue = chartValues[i].x
            let yValue = chartValues[i].y
            let value = ChartDataEntry(x: Double(i), y: Double(yValue))
            
            days.append(xValue)
            chartEntry.append(value)
        }
        
        //Convert the entry to a data set
        let line = LineChartDataSet(chartEntry)
        line.colors = [chartColor]
        line.drawCirclesEnabled = false
        line.fill = Fill.fillWithCGColor(chartColor.cgColor)
        line.fillAlpha = 0.6
        line.drawFilledEnabled = true
        line.lineWidth = 2.0
        
        //Data to add to the chart
        let data = LineChartData()
        data.addDataSet(line)
        data.setDrawValues(false)
    
        chartView.data = data
        chartView.legend.enabled = false
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.labelTextColor = .white
        chartView.leftAxis.labelTextColor = .white
        chartView.rightAxis.enabled = false
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: days)
        chartView.xAxis.granularity = 1.0
        chartView.xAxis.axisMinimum = Double(xAxisMin)
        chartView.leftAxis.axisMinimum = 0
        
    }
    
    @IBAction func changeChartType(_ sender: UISegmentedControl) {
        setChartProperties()
    }
    

}

// MARK: API Calls
extension StatisticsTableViewController {
    func dailyGlobalCases(caseType: String) {
        var result: [(x: String, y: Int)] = []
        
        guard let url = URL(string: "https://covid19.mathdro.id/api/daily")
            else {
                print("Error while getting api url")
                return
            }
        
        let session = URLSession.shared
        
        session.dataTask(with: url, completionHandler: { (data, response, error) in
            if let data = data {
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]] {
                        
                        for data in json {
                            let caseType = data[caseType] as? [String:Any]

                            let caseNumber = caseType?["total"] as? Int ?? 0
                            let day = data["reportDate"] as? String ?? ""
                            let formatedDay = Date.getFormattedDate(dateToFormat: day, originalFormat: "yyyy-MM-dd", newFormat: "dd/MM")
                            
                            let value = (x: formatedDay, y: caseNumber)
                            
                            result.append(value)
                        }
                        
                        DispatchQueue.main.async {
                            self.plotGraphic(chartColor: self.chartColor, chartValues: result, xAxisMin: 0)
                            self.tableView.reloadData()
                        }
                    }
                } catch { print(error) }
            }
        }).resume()
    }
    
    func dailyCountryCases(country: String, caseType: String) {
        var result: [(x: String, y: Int)] = []
        
        guard let url = URL(string: "https://api.covid19api.com/total/country/\(country)")
            else {
                print("Error while getting api url")
                return
            }
        
        let session = URLSession.shared
        
        session.dataTask(with: url, completionHandler: { (data, response, error) in
            if let data = data {
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]] {
                        
                        var foundFirstConfirmed: Bool = false
                        var dayCounter: Int = 0
                        
                        for data in json {
                            let confirmedNumber = data["Confirmed"] as? Int ?? 0
                            let caseNumber = data[caseType] as? Int ?? 0
                            let day = data["Date"] as? String ?? ""
                            
                            let formatedDay = Date.getFormattedDate(dateToFormat: day, originalFormat: "yyyy-MM-dd'T'HH:mm:ssZ", newFormat: "dd/MM")
                            let value = (x: formatedDay, y: caseNumber)
                            
                            if !foundFirstConfirmed && confirmedNumber != 0 {
                                foundFirstConfirmed = true
                            } else if !foundFirstConfirmed {
                                dayCounter += 1
                            }
                            
                            result.append(value)
                        }
                        
                        DispatchQueue.main.async {
                            self.plotGraphic(chartColor: self.chartColor, chartValues: result, xAxisMin: dayCounter - 1)
                            self.tableView.reloadData()
                        }
                    }
                } catch { print(error) }
            }
        }).resume()
    }
                        
}

// MARK: TableView Controller Functions
extension StatisticsTableViewController {
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let titleView = UIView()
        let labelHeight: CGFloat = 18
        
        let label = UILabel(frame: CGRect(x: 0,
                                          y: headerHight - labelHeight - 12,
                                          width: self.view.frame.size.width,
                                          height: labelHeight))
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.numberOfLines = 0
        
        switch section {
        case 0:
            label.text = "Localização"
        case 1:
            label.text = "Gráficos de estatísticas"
        case 2:
            label.text = "Visão geral"
        default:
            label.text = "Needs to be specified"
        }
        
        titleView.addSubview(label)

        return titleView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return headerHight
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (indexPath.row == 0 && indexPath.section == 2) {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! VisaoGeralTableViewCell
            
            if (self.coronaStatistics != nil) {
                
                cell.confirmedNumber.text = formatNumber(number: coronaStatistics[0])
                cell.recoveredNumber.text = formatNumber(number: coronaStatistics[1])
                cell.activeNumber.text = formatNumber(number: coronaStatistics[2])
                cell.deathsNumber.text = formatNumber(number: coronaStatistics[3])
            }
            
            return cell
            
        } else {
        
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
            
            switch indexPath.section {
            case 0:
                let chevron = UIImage(named: "chevron-icon")
                cell.accessoryType = .disclosureIndicator
                cell.accessoryView = UIImageView(image: chevron!)
                self.countryIcon.image = self.country.image
                self.disclosureLabel.text = self.country.name
            default:
                break
            }
            
            return cell
        }
    }
    
    // MARK: - API Functions
    func getCasesNumber(location: String) {
        // Builds an array with
        // confirmed, recoreved, active
        // and deaths cases, using corona api
        
        var apiURL: String!
        
        if (location == "Mundo") {
            apiURL = "https://covid19.mathdro.id/api/"
        } else {
            apiURL = "https://covid19.mathdro.id/api/countries/\(location)"
        }
        
        guard let url = URL(string: apiURL)
            
            else {
                print("Error while getting api url")
                return
            }
        
        let session = URLSession.shared
        
        session.dataTask(with: url) { (data, response, error) in
            
            if let data = data {
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        
                        if let deaths = json["deaths"] as? [String:Any],
                           let recovered = json["recovered"] as? [String:Any],
                           let confirmed = json["confirmed"] as? [String:Any] {
                            
                            let deathsNumber = deaths["value"] as? Int ?? 0
                            let confirmedNumber = confirmed["value"] as? Int ?? 0
                            let recoveredNumber = recovered["value"] as? Int ?? 0
                            let activeNumber = confirmedNumber - deathsNumber - recoveredNumber
                            self.coronaStatistics = [confirmedNumber, recoveredNumber, activeNumber, deathsNumber]
                         }
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    
                } catch { print(error) }
            }
        }.resume()
    }
    
    // MARK: - Auxiliary Functions
    
    func formatNumber(number: Int) -> String {
        // Formats large numbers to
        // a String with a comma
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let formattedNumber = numberFormatter.string(from: NSNumber(value:number)) ?? "-"
        
        return formattedNumber
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (indexPath.row == 0 && indexPath.section == 0){

            if let viewController = storyboard?.instantiateViewController(identifier: "Filter") as? FilterTableViewController {
                viewController.delegate = self
                navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }
}

// MARK: Date Formatter
extension Date {
    static func getFormattedDate(dateToFormat: String, originalFormat: String, newFormat:String) -> String {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = originalFormat

        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = newFormat

        let date: Date? = dateFormatterGet.date(from: dateToFormat)
        return dateFormatterPrint.string(from: date!);
    }
    
}

extension StatisticsTableViewController: selectedCountryProtocol{
    func setCountry(country: Country) {
        
        self.country = country
        navigationController?.popViewController(animated: true)
        self.tableView.reloadData()

    }
    
    
}
