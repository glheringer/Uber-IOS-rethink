//
//  DriverTableViewController.swift
//  Uber
//
//  Created by Rethink on 04/04/22.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import CoreLocation
import MapKit

class DriverTableViewController: UITableViewController, CLLocationManagerDelegate{
    
    var requestList : [DataSnapshot] = []
    let locationManager = CLLocationManager()
    var driverLocation = CLLocationCoordinate2D()
    var timerController = Timer()
    
    @IBAction func userLogout(_ sender: Any) {
        
        let auth = Auth.auth()
        do {
            try auth.signOut() //Funcao deslogar
            dismiss(animated: true, completion: nil)
        } catch  {
            print("Erro ao deslogar usuario")
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Configurar Localizacao do Motorista
        configDriverLocation()
        
        //Limpar lista inicialmente
        self.requestList = []
        self.requestList
        
        //Configurar banco de dados
        let database = Database.database().reference()
        let request = database.child("requisicao")
        
//        //Recuperar requisicoes
//        request.observe(.childAdded) { (snapshot) in
//            
//            self.requestList.append(snapshot)
//            self.tableView.reloadData()
//        }
        
        //Limpa requisicao caso o usuario cancele o uber
        request.observe(.childRemoved) { (snapshot) in
            var index = 0
            for request in self.requestList {
                //snapshot.kye retorna o identificador do snap ai é comparado e excluido do array
                if request.key == snapshot.key{
                    self.requestList.remove(at: index)
                }
                index += 1
                
            }
            self.tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.recoverRequest()
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
            
            self.recoverRequest()
            self.timerController = timer
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        self.timerController.invalidate()
        
    }
    
    func recoverRequest(){

        //Configurar banco de dados
        let database = Database.database().reference()
        let request = database.child("requisicao")
        
        //Limpar a atual lista de requisicoes
        self.requestList = []
        
        //Recuperar requisicoes
        request.observeSingleEvent(of: .childAdded) { (snapshot) in
            
            self.requestList.append(snapshot)
            self.tableView.reloadData()
        }
        
    }
    
    //Configurar Localizacao do Motorista
    func configDriverLocation(){
        
        locationManager.delegate = self //Delegando a propria classe para controlar o gerenciador de localizacao
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //Melhor atualizacao de localizacao do usuario
        locationManager.requestWhenInUseAuthorization() //Pedir ao usuario permissao para autorizacao enquanto usa
        locationManager.startUpdatingLocation() //Comecar a coletar localizacao do usuario
        
    }
    
    //Atualizar localizacao do motorista,a cada mudanca ele recupera a localizacao do motorista
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let coordinate = manager.location?.coordinate{
            self.driverLocation = coordinate
        }
    }
    //Assim que a linha da tabela for clicada executa as acoes dentro da funcao
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let snapshot = self.requestList[indexPath.row] //seleciona a linha da tabela clicada
        
        performSegue(withIdentifier: "acceptRunSegue", sender: snapshot)
        
    }
    //Configurar dados da tela de requisicoes
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "acceptRunSegue"{
            if let runVC = segue.destination as? RunViewController{
                
                let snapshot = sender as! DataSnapshot
                
                let data = snapshot.value as? NSDictionary
                
                runVC.namePassenger = data!["nome"] as! String
                runVC.emailPassenger = data!["email"] as! String
                
                runVC.passengerLocation = CLLocationCoordinate2D(latitude: data!["latitude"] as! CLLocationDegrees, longitude: data!["longitude"] as! CLLocationDegrees)
                
                runVC.driverLocation = self.driverLocation
                
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.requestList.count

    }

   
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseCell", for: indexPath)

        let snapshot = self.requestList[indexPath.row]
        if let data = snapshot.value as? [String: Any]{
            
            if let userLatitude = data["latitude"] as? Double{ //Recupera Latitude do Usuario de dentro do array
                if let userLongitude = data["longitude"] as? Double {//Recupera Longitude do Usuario de dentro do array
                    
                    //Configura posicao do motorista
                    let driverPosition = CLLocation(latitude:self.driverLocation.latitude, longitude: self.driverLocation.longitude)
                    //Configura posicao do passageiro
                    let userPosition = CLLocation(latitude: userLatitude, longitude: userLongitude)
                    
                    //Distancia entre os pontos, em metros
                    let mettersDistanceBtw = driverPosition.distance(from: userPosition)
                    
                    //Distancia entre os pontos, em KMs
                    let KMDistanceBtw = mettersDistanceBtw / 1000
                    
                    //Distancia entre os pontos, arrendondada
                    let finalDistanceBtw = KMDistanceBtw.rounded()
                    
                    
                    var driverRequest = ""
                    if let driverEmailR = data["motoristaEmail"] as? String{
                        let auth = Auth.auth()
                        if let loggedDriver = auth.currentUser?.email{
                            if driverEmailR == loggedDriver{
                                driverRequest = " {ANDAMENTO} "
                            }
                            else{
                                print("Erro ao definir status")
                            }
                        }
                    }
                    //Fazer com que se o email do motorista logado nessa secao for igual ao do motorista da requisicao, exibir que a corrida está em andamento, adicionar no RunViewController tbm o dado de email para o motorista
                    if let passengerName = data["nome"] as? String{
                        cell.textLabel?.text = "\(passengerName) / \(driverRequest) "
                        cell.detailTextLabel?.text = "\(finalDistanceBtw) KM de distancia "
                    }
                 
                }
            }
          
        }


        
        
        return cell
    }


    
}
