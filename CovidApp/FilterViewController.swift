//
//  FilterViewController.swift
//  CovidApp
//
//  Created by Kaan Ezerrtaş on 23.12.2023.
//

import UIKit

class FilterViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    public var completion : ((State) -> Void)? //completion adında bir closure tanımlıyoruz. Bu closure, bir State nesnesini parametre olarak alacak ve Void (geri dönüş değeri olmayan) bir fonksiyonu temsil edecek.
    
    //MARK: TABLEVIEW
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
        
    }()
    
    private var states: [State] = [] { // states adında bir State dizisi tanımlanıyor.
        didSet { //Dizi değiştiğinde (didSet), tableView'nin verilerini güncellemek için ana thread üzerinde reloadData çağrılıyor.
            DispatchQueue.main.async{
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground //Görünümün arka plan rengi ayarlanıyor, başlık belirleniyor.
        title = "Select State" //Başlık belirliyoruz
        view.addSubview(tableView) //tableView ekranın üzerine ekleniyor.
        tableView.delegate = self //tableView'nin delegate özellikleri self (yani bu ViewController) ile ayarlıyoruz.
        tableView.dataSource = self //tableView'nin  dataSource özellikleri self (yani bu ViewController) ile ayarlanıyor.
        fetchStates() //fetchStates fonksiyonu çağrılarak eyalet verileri getiriliyor
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapClose)) //Sol üst köşede "Close" butonu ekleniyor.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds //TableView'nin boyutunu, ViewController'ın görünümünün boyutuna eşitleme.
    }
    
    @objc private func didTapClose() { //Close butonuna tıklandığında çağrılan fonksiyon.
        dismiss(animated: true,completion: nil) //ViewController'ı kapatma işlemi gerçekleştiriliyor.
    }
    
    private func fetchStates() { //Eyalet verilerini getiren ve states dizisini güncelleyen asenkron bir fonksiyon yazıyoruz.
        APICaller.shared.getStateList { [weak self] result in //APICaller sınıfının getStateList fonksiyonunu kullanarak eyalet verilerini çekiyor.
            switch result { //Başarılı olursa, states dizisini güncelliyor; başarısız olursa hatayı yazdırıyor.(print uyarısı)
            case .success(let states):
                self?.states = states
            case .failure(let error):
                print("Error fetching states: \(error)")
            }
        }
    }
    
   //MARK: TABLEVIEW
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return states.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let state = states[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = state.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let state = states[indexPath.row]
        completion?(state)
        dismiss(animated: true, completion: nil)
        
    }

}
