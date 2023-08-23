//
//  ViewController.swift
//  Lab3
//
//  Created by Milind Kate on 2023-03-15.
//

import UIKit
import CoreLocation

class ViewController: UIViewController,UITextFieldDelegate {
    
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var weatherConditionImage: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var temperatureSwitch: UISwitch!
    @IBOutlet weak var weatherCondition: UILabel!
    
    var celcius:String = ""
    var fahren:String = ""
    private var latitude: Double?
    private var longitude: Double?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        displaySampleImageForDemo(name:"snowflake")
        searchTextField.delegate = self
    }
    
    func getCurrentLocation()
    {
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    func textFieldShouldReturn(_ textField:UITextField) -> Bool{
        textField.endEditing(true)
        loadWeather(search: textField.text)
        return true
    }

    private func displaySampleImageForDemo(name: String){
        
        let config = UIImage.SymbolConfiguration(paletteColors: [
            .systemGreen, .systemPurple, .systemRed
        ])
        weatherConditionImage.preferredSymbolConfiguration = config
        
        weatherConditionImage.image = UIImage(systemName:name)
    }

    @IBAction func onLocationTapped(_ sender: UIButton) {
        getCurrentLocation()
    }
    
    @IBAction func onSearchTapped(_ sender: UIButton) {
        loadWeather(search: searchTextField.text)
    }
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        if temperatureSwitch.isOn{
            temperatureLabel.text = "Celcius: \(celcius)"
        }
        else{
            temperatureLabel.text = "Fahrenheit: \(fahren)"
        }
    }
    
    private func loadWeather(search:String?)
    {
        guard let search = search else{
            return
        }
        
        guard let url = getURL(query: search) else{
            print("Could not get URL")
            return
        }
        
        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: url) { data, response, error in
            print("Network call complete")
            
            guard error == nil else{
                print("Error")
                return
            }
            
            guard let data = data else{
                print("No data found")
                return
            }
            
            if let weatherResponse = self.parseJson(data: data){
                DispatchQueue.main.async {
                    self.locationLabel.text = weatherResponse.location.name
                    self.temperatureLabel.text = "Celcius: \(weatherResponse.current.temp_c)C"
                    
                    self.celcius = "\(weatherResponse.current.temp_c)C"
                    self.fahren = "\(weatherResponse.current.temp_f)F"
                    self.weatherCondition.text = weatherResponse.current.condition.text
                    self.getImage(code:weatherResponse.current.condition.code)
                    print("WEATHER CONDITION CODE -> \(weatherResponse.current.condition.code)")
                    
                }
            }
        }
        
        dataTask.resume()
        
    }
    
    private func getURL(query:String) -> URL?{
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "current.json"
        let apiKey = "8e2a5feb8fd64e8baf513859231603"
        
        guard let url = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&q=\(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else{
            return nil
        }
        
        return URL(string: url)
    }
    
    private func parseJson(data:Data) -> WeatherResponse?{
        let decoder = JSONDecoder()
        var weather:WeatherResponse?
        do{
            weather = try decoder.decode(WeatherResponse.self, from: data)
        }catch
        {
            print("Error decoder")
        }
        return weather
    }
    
    private func getImage(code: Int){
        switch code {
        case 1000:
            displaySampleImageForDemo(name: "sun.max.circle.fill")
        case 1006:
            displaySampleImageForDemo(name: "cloud")
        case 1009:
            displaySampleImageForDemo(name: "cloud.sun.fill")
        case 1114:
            displaySampleImageForDemo(name: "snowflake.circle.fill")
        case 1117:
            displaySampleImageForDemo(name: "snowflake")
        case 1255:
            displaySampleImageForDemo(name: "snowflake.road.lane")
        default:
            displaySampleImageForDemo(name: "cloud.sun.fill")
        }
    }
}

extension ViewController:CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue:CLLocationCoordinate2D = manager.location?.coordinate else { return }
        latitude = locValue.latitude
        longitude = locValue.longitude
        print("Locations: \(locValue.latitude) \(locValue.longitude)")
        
        if let lat = latitude, let long = longitude {
            let search = "\(lat),\(long)"
            loadWeather(search: search)
        }
    }
}

struct WeatherResponse : Decodable{
    let location:Location
    let current:Weather
}

struct Location: Decodable{
    let name:String
}

struct Weather: Decodable{
    let temp_c:Float
    let temp_f:Float
    let condition:WeatherCondition
}

struct WeatherCondition: Decodable{
    let text: String
    let code:Int
}
