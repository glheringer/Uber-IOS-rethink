//
//  RunViewController.swift
//  Uber
//
//  Created by Rethink on 06/04/22.
//

import UIKit
import MapKit
import FirebaseDatabase
import FirebaseAuth

enum runStatus: String{
    case  onRequest, passengerOnboard, startedTrip, traveling
}
   //Em requisicao, passageiro pego, iniciada viagem, em viagem

class RunViewController : UIViewController, CLLocationManagerDelegate{
    
    var namePassenger = ""
    var emailPassenger = ""
    var passengerLocation = CLLocationCoordinate2D()
    var driverLocation = CLLocationCoordinate2D()
    var destinationLocation = CLLocationCoordinate2D()
    var status : runStatus = .onRequest
    var locationManager = CLLocationManager()
    
    @IBOutlet weak var map: MKMapView!
    
    @IBOutlet weak var acceptRunButton: UIButton!
    
    @IBAction func acceptRun(_ sender: Any) {
        //Nesse metodo iremos aceitar a corrida, configurar a localizacao do usuario como a do motorista e traçar uma rota entre eles
        
        if self.status == .onRequest {
            
            //Atualizar requisicao
            let database = Database.database().reference()
            let auth = Auth.auth()
            let requests = database.child("requisicao")
            
            if let driverEmail = auth.currentUser?.email{
                //Recuperar requisicao a partir de um dado do usuario que ja temos, no caso email, usando um filtro
                requests.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassenger)
                    .observeSingleEvent(of: .childAdded) { (snapshot) in
                        
                        //Configurar lati/longi  do motorista no lugar da lati/longi do usuario
                        let driverData = [
                            "motoristaEmail" : driverEmail,
                            "motoristaLatitude" : self.driverLocation.latitude,
                            "motoristaLongitude" : self.driverLocation.longitude,
                            "status": runStatus.passengerOnboard.rawValue
                            
                        ] as [String: Any]
                        
                        //Capturar requisicao novamente e atualizar suas "Childs"(atributos) com os valores do Motorista
                        snapshot.ref.updateChildValues(driverData)
                        
                        //Chamar metodo pegar passageiro
                        self.pickUpPassenger()
                        
                        //Exibir caminho para o passageiro no mapa
                        let passengerCLL = CLLocation(latitude: self.passengerLocation.latitude, longitude: self.passengerLocation.longitude)
                      
                        //Configurando rota para o passageiro
                        CLGeocoder().reverseGeocodeLocation(passengerCLL) { (local, erro)  in
                            if erro == nil{
                                if let localData = local?.first{
                                    
                                    let placemark = MKPlacemark(placemark: localData)
                                    let mapItem = MKMapItem(placemark: placemark)
                                    
                                    mapItem.name = self.namePassenger
                                    
                                    let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                                    
                                    mapItem.openInMaps(launchOptions: options)
                                    
                                }
                            }
                                
                        }
                    }
            }
        }
        
    }
    
    //Pegar passageiro
    func pickUpPassenger () {
        
        //Alterar Status
        self.status = .passengerOnboard
        //Alternar Botao
        self.switchButtonPickUpPassenger()
    }
    
    //Atualizar localizacao do motorista,a cada mudanca ele recupera a localizacao do motorista
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = manager.location?.coordinate{
           
            self.driverLocation = coordinate
            self.updateDriverLocation()
            
        }
    }
    
    //Atualizar localizacao do motorista e status da requisicao
    func updateDriverLocation(){
        
        let database = Database.database().reference()
        
        if self.emailPassenger != "" {
            let requests = database.child("requisicao")
            let listRequests = requests.queryOrdered(byChild: "email").queryEqual(toValue: emailPassenger)
    
            listRequests.observeSingleEvent(of: .childAdded) { (snapshot) in
                
                if let data = snapshot.value as? [String : Any] {
                    if let statusR = data["status"] as? String{
                        
                        if statusR == runStatus.passengerOnboard.rawValue{
                            
                            /*Verifica se o Motorista está próximo, para
                             iniciar a corrida
                             */
                            
                            //Calcula distância entre motorista e passageiro
                            let driverLocation = CLLocation(latitude: self.driverLocation.latitude, longitude: self.driverLocation.longitude)
                            let passengerLocation = CLLocation(latitude: self.passengerLocation.latitude, longitude: self.passengerLocation.longitude)
                            
                            //Calcula distancia entre motorista e passageiro
                            let distance = driverLocation.distance(from: passengerLocation)
                            let distanceKM = distance / 1000
                            
                            var newStatus = self.status.rawValue
                            //Quando o motorista estiver a 500 metros do passageiro ele pode mudar o status para iniciar Viagem
                            if distanceKM <= 0.5 {
                                //Atualizar status
                                newStatus = runStatus.startedTrip.rawValue
                            }
                            
                            
                            let driverData = [
                                "motoristaLatitude" : self.driverLocation.latitude,
                                "motoristaLongitude" : self.driverLocation.longitude,
                                "status": newStatus
                            ] as [String : Any]
                            
                            //Salvar dados no Firebase
                            snapshot.ref.updateChildValues(driverData)
                            
                            //Mudar status
                            self.pickUpPassenger()
                            
                            
                            self.showDriverPassenger(lStart: self.driverLocation, lDestiny: self.passengerLocation, tStart: "Meu Local", tDestiny: "Passageiro")
                            
                        } //fim if status ==
                
                        else if(statusR == runStatus.startedTrip.rawValue){
                            self.switchButtonStartedTrip()
                            
                            if let latDestination = data["destinoLatitude"] as? Double {
                                if let lonDestination = data["destinoLongitude"] as? Double{
                                    
                                    self.destinationLocation = CLLocationCoordinate2D(latitude: latDestination, longitude: lonDestination)
                                    
                                    
                                    //Exibir motorista passageiro
                                    self.showDriverPassenger(lStart: self.passengerLocation, lDestiny: self.destinationLocation, tStart: "Motorista", tDestiny: "Passageiro")
                                }
                            }
                            
                        }
                    }
                }
            }
        }
    }
    //Mostrar ponto final e inicial, dois locais
    func showDriverPassenger(lStart: CLLocationCoordinate2D , lDestiny: CLLocationCoordinate2D, tStart: String, tDestiny: String){
        
        //Exibir passageiro e motorista no mapa
        map.removeAnnotations(map.annotations)
        
        //Calcular a diferenca de entre passageiro e usuario, de forma que possa ser exibido os dois no mapa
        let latDiference = abs(lStart.latitude - lDestiny.latitude) * 300000
        let longDiference = abs(lStart.longitude - lDestiny.longitude) * 300000
        
        let region = MKCoordinateRegion(center: lStart, latitudinalMeters: latDiference, longitudinalMeters: longDiference)
        map.setRegion(region, animated: true)
        
        //Start Annotation
        let passengerAnnotation = MKPointAnnotation()
        passengerAnnotation.coordinate = lStart
        passengerAnnotation.title = tStart
        map.addAnnotation(passengerAnnotation)
        
//        //Destiny Annotation
//        let driverAnnotation = MKPointAnnotation()
//        driverAnnotation.coordinate = lDestiny
//        driverAnnotation.title = tDestiny
//        map.addAnnotation(driverAnnotation)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Configura locacalizacao do usuario para uso
        self.configDriverLocation()
        
        //Configurar area Inicial do mapa
        let region = MKCoordinateRegion.init(center: passengerLocation, latitudinalMeters: 3000, longitudinalMeters: 3000)
        map.setRegion(region, animated: true)
        
        //Criar Anotacao para localizacao do usuario
        let passengerAnnotation = MKPointAnnotation()
        passengerAnnotation.coordinate = self.passengerLocation
        passengerAnnotation.title = self.namePassenger
        map.addAnnotation(passengerAnnotation)
        
    }
    
    //Alterna botao para pegar passageiro
    func switchButtonPickUpPassenger(){
        
        self.acceptRunButton.setTitle("A caminho do passageiro", for: .normal)
        self.acceptRunButton.isEnabled = false
        self.acceptRunButton.backgroundColor = UIColor(displayP3Red: 0.502, green: 0.502, blue: 0.502, alpha: 1)
        
        
    }
    
    //Alterna botao para iniciar viagem
    func switchButtonStartedTrip(){
        
        self.acceptRunButton.setTitle("Iniciar Viagem", for: .normal)
        self.acceptRunButton.isEnabled = true
        self.acceptRunButton.backgroundColor = UIColor(displayP3Red: 0.067, green: 0.576, blue: 0.604, alpha: 1)
        
        
    }
    //Configura locacalizacao do usuario para uso
    func configDriverLocation(){
        
        locationManager.delegate = self //Delegando a propria classe para controlar o gerenciador de localizacao
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //Melhor atualizacao de localizacao do usuario
        locationManager.requestWhenInUseAuthorization() //Pedir ao usuario permissao para autorizacao enquanto usa
        locationManager.startUpdatingLocation() //Comecar a coletar localizacao do usuario
        locationManager.allowsBackgroundLocationUpdates = true //Permitir que a localizacao seja atualizada em background (enquanto app estiver fechado)
    }
}
