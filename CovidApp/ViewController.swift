//
//  ViewController.swift
//  CovidApp
//
//  Created by Kaan Ezerrtaş on 23.12.2023.
//
import Charts //import Charts ifadesi, iOS uygulamalarında grafikler oluşturmak için kullanılan popüler bir grafik çizme kütüphanesi olan "Charts" kütüphanesini içe aktarır. Bu kütüphane, bar grafikleri, çizgi grafikleri, pasta grafikleri ve diğer çeşitli grafik türlerini oluşturmak için kullanılır.
import DGCharts
import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    //MARK: NUMBERFORMATTER
    static let numberFormatter: NumberFormatter = { //Bu, sayıları biçimlendirmek için kullanılan bir NumberFormatter örneğini tanımlıyoruz. Sayıları binlik grup ayırıcısıyla (virgül) formatlar.
       let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.formatterBehavior = .default
        
        formatter.locale = .current
        
        return formatter
    }()
    
    //MARK: TABLEVIEW
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
        
    }()
    
    private var dayData: [DayData] = [] { //dayData adında bir DayData dizisi tanımlanır.
        didSet{ //Dizi değiştiğinde (didSet), tableView'yi ve bir grafik oluşturan createGraph fonksiyonunu günceller.
            DispatchQueue.main.async{
                self.tableView.reloadData()
                self.createGraph()
            }
        }
    }
    
    private var scope: APICaller.DataScope = .national //scope adında bir APICaller.DataScope enumu tanımlanır ve başlangıçta .national olarak atanır.

    //MARK: Görünümün Yüklenmesi
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Covid Vakaları"
        configureTable()
        createFilterButton()
        fetchData()
        
    }
    //MARK: Görünüm Boyutunun Güncellenmesi
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    //MARK: Grafik Oluşturma
    private func createGraph() { // Grafik oluşturma işlemleri...
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.width/1.5))
        headerView.clipsToBounds = true
        let set = dayData.prefix(30)
        var entries: [BarChartDataEntry] = []
        for index in 0..<set.count {
            let data = set[index]
            entries.append(.init(x: Double(index), y: Double(data.count)))
        }
        
        
        let dataSet = BarChartDataSet(entries: entries
        )
        dataSet.colors = ChartColorTemplates.joyful()
        let data: BarChartData = BarChartData(dataSet: dataSet)
        
        let chart = BarChartView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.width/1.5))
        
        chart.data = data
        
        headerView.addSubview(chart)
        
        tableView.tableHeaderView = headerView
    }
    //MARK: Tablo Konfigürasyonu
    private func configureTable() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
    }
    //MARK: Veri Çekme
    private func fetchData() {
        APICaller.shared.getCovidData(for: scope) { [weak self] result in
            switch result  {
            case .success(let dayData):
                self?.dayData = dayData
            case .failure(let error):
                print(error)
            }
        }
    }
    //MARK: Filtreleme Düğmesi Oluşturma
    private func createFilterButton(){
        let Buttontitle: String = {
            switch scope {
            case .national: return "Uluslararası"
            case .state(let state): return state.name
            }
        }()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Buttontitle,style: .done,target: self, action: #selector(didTapFilter))
    }
    //MARK: Filtreleme Düğmesine Tıklanınca Çağrılan Fonksiyon
    @objc private func didTapFilter() {
        let vc = FilterViewController()
        vc.completion = { [weak self] state in
            self?.scope = .state(state)
            self?.fetchData()
            self?.createFilterButton()
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    //MARK: TABLE
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dayData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = dayData[indexPath.row]
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = createText(with: data)
        return cell
    }
    
    private func createText(with data: DayData) -> String? {
        let dateString = DateFormatter.prettyFormatter.string(from: data.date)
        let total = Self.numberFormatter.string(from: NSNumber(value: data.count))
        return "\(dateString): \(total ?? "\(data.count)")"
    }
    
}

