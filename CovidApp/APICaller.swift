//
//  APICaller.swift
//  CovidApp
//
//  Created by Kaan Ezerrtaş on 23.12.2023.
//

import Foundation

extension DateFormatter {
    
    //MARK: DateFormatter sınıfına ait iki adet özel format belirleyen DateFormatter uzantısı tanımladık. dayFormatter tarihi "YYYY-MM-dd" formatında,
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()
    
    //MARK: prettyFormatter ile tarihi orta derecede okunabilir bir formatta biçimlendirmek için kullanılır.
    static let prettyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()
}
//MARK: API
class APICaller {
    static let shared = APICaller()
    
    private init () {}
    
    private struct Constants {
        static let allStatesUrl = URL(string: "https://api.covidtracking.com/v2/states.json")
        
    }
    
    enum DataScope {
        case national
        case state(State)
    }
    //MARK: getCovidData fonksiyonu, belirtilen kapsama (DataScope) göre COVID-19 günlük verilerini çeker ve tamamlama bloğuna bir dizi DayData veya bir hata (Error) döner.
    public func getCovidData(for scope: DataScope, completion: @escaping (Result<[DayData], Error>) -> Void
    ) {
        let urlString: String
        switch scope {
        case .national:
            urlString = "https://api.covidtracking.com/v2/us/daily.json"
        case .state(let state):
            urlString =  "https://api.covidtracking.com/v2/states/\(state.state_code.lowercased())/daily.json"
        }
        
        guard let url = URL(string: urlString) else {return}
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {return}
            
            do {
                let result = try JSONDecoder().decode(CovidDataResponse.self, from: data)
                
                let models: [DayData] = result.data.compactMap {
                    guard let value = $0.cases?.total.value,
                            let date = DateFormatter.dayFormatter.date(from: $0.date) else {
                        return nil
                    }
                    return DayData(date: date,
                                   count: value
                    )
                   
                }
                completion(.success(models))
            }catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    //MARK: getStateList fonksiyonu, tüm eyaletlerin listesini çeker ve tamamlama bloğuna bir dizi State veya bir hata (Error) döner.
    public func getStateList(completion: @escaping (Result<[State], Error>) -> Void) {
        guard let url = Constants.allStatesUrl else {return}
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {return}
            
            do {
                let result = try JSONDecoder().decode(StateListResponse.self, from: data)
                let states = result.data
                completion(.success(states))
            }catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    
}

//MARK: MODEL

struct StateListResponse: Codable {
    let data: [State]
}

struct State: Codable {
    let name: String
    let state_code: String
}

struct CovidDataResponse: Codable {
    let data: [CovidDayData]
}

struct CovidDayData: Codable {
    let cases: CovidCases?
    let date: String
}

struct CovidCases: Codable {
    let total: TotatCases
}

struct TotatCases: Codable {
    let value: Int?
}

struct DayData {
    let date: Date
    let count: Int
}
