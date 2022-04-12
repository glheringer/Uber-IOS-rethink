//
//  PassengerViewController.swift
//  Uber
//
//  Created by Rethink on 31/03/22.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import MapKit

class PassengerViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    var driverLocation = CLLocationCoordinate2D()
    var uberCalled = false
    var uberIncoming = false
    
    @IBOutlet weak var adressText: UIView!
    @IBOutlet weak var userLocalMark: UIView!
    @IBOutlet weak var destinationMark: UIView!
    @IBOutlet weak var destinationTxtField: UITextField!
    
    @IBOutlet weak var buttonCallUber: UIButton!
    @IBOutlet weak var map: MKMapView!
    @IBAction func userLogout(_ sender: Any) { //Botao deslogar
        
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
        
        self.configUserLocation()
        
        //Configura marcadores de endereço e destino do usuário
        self.userLocalMark.layer.cornerRadius = 7.5
        self.destinationMark.layer.cornerRadius = 7.5
        self.adressText.layer.cornerRadius = 10
        
        
        //Verifica se o usuario(passageiro) ja pediu um Uber
        let database = Database.database().reference()
        let auth = Auth.auth()
        
        if let userEmail = auth.currentUser?.email{
            
            let requests = database.child("requisicao")
            
            //Recuperar requisicao do usuario com determinado email
            let searchedRequest = requests.queryOrdered(byChild: "email").queryEqual(toValue: userEmail)
            
            //Observa se foi chamado um uber
            searchedRequest.observeSingleEvent(of: .childAdded) { (snapshot) in
                
                if snapshot.value != nil {
                    self.switchButtonCancellUber()
                }
            }
            
            //Observa se o motorista aceitou a corrida
            searchedRequest.observe(.childChanged) { (snapshot) in
                
                if let data = snapshot.value as? [String: Any]{
                    if let status = data["status"] as? String {
                        if status == runStatus.passengerOnboard.rawValue {
                            
                            if let latDriver = data["motoristaLatitude"]{
                                if let longiDriver = data["motoristaLongitude"]{
                                    self.driverLocation =
                                    CLLocationCoordinate2D(latitude: latDriver as! CLLocationDegrees, longitude: longiDriver as! CLLocationDegrees)
                                    
                                    self.showDriverMessage()
                                }
                                
                            }
                            
                        }else if(status == runStatus.startedTrip.rawValue){
                            self.switchButtonStartedTrip()
                            
                        }
                    }
                }
            }
        }
    }
    func showDriverMessage(){
        self.uberIncoming = true
        
        //Calcular a distancia  entre motorista e passageiro
        let driverLocation = CLLocation(latitude: self.driverLocation.latitude, longitude: self.driverLocation.longitude)
        
        let passengerLocation = CLLocation(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
        
        //Calcular a distancia  entre motorista e passageiro
        var message = ""
        let distance = driverLocation.distance(from: passengerLocation)
        let KMdistance = distance / 1000
        let finalDistance = round(distance)
        message = "Motorista \(finalDistance) KM distante"
        
        if KMdistance < 1 {
            let Mdistance = round(distance)
            message = "Motorista \(Mdistance) M distante"
        }
        
        self.buttonCallUber.backgroundColor = UIColor(displayP3Red: 0.067, green: 0.576, blue: 0.604, alpha: 1)
        self.buttonCallUber.setTitle(message, for: .normal)
        
        //Exibir passageiro e motorista no mapa
        map.removeAnnotations(map.annotations)
        
        //Calcular a diferenca de entre passageiro e usuario, de forma que possa ser exibido os dois no mapa
        //let latDiference = abs(self.userLocation.latitude - self.userLocation.latitude) * 300000
        // let longDiference = abs(self.userLocation.longitude - self.userLocation.longitude) * 300000
        
        let region = MKCoordinateRegion(center: self.userLocation, latitudinalMeters: 2000, longitudinalMeters: 2000)
        map.setRegion(region, animated: true)
        
//        //Passenger Annotation
//        let passengerAnnotation = MKPointAnnotation()
//        passengerAnnotation.coordinate = self.userLocation
//        passengerAnnotation.title = "Passageiro"
//        map.addAnnotation(passengerAnnotation)
        
        //Driver Annotation
        let driverAnnotation = MKPointAnnotation()
        driverAnnotation.coordinate = self.driverLocation
        driverAnnotation.title = "Motorista"
        map.addAnnotation(driverAnnotation)
        
    }
    //Configurar Localizacao do Usuario
    func configUserLocation(){
        
        self.map.delegate = self
        locationManager.delegate = self //Delegando a propria classe para controlar o gerenciador de localizacao
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //Melhor atualizacao de localizacao do usuario
        locationManager.requestWhenInUseAuthorization() //Pedir ao usuario permissao para autorizacao enquanto usa
        locationManager.startUpdatingLocation() //Comecar a coletar localizacao do usuario
        locationManager.allowsBackgroundLocationUpdates = true //Permitir que a localizacao seja atualizada em background (enquanto app estiver fechado)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { //Metodo para atualizar localizacao do usuario, a cada mudanca ele recupera a localizacao do usuario
        
        //Recuperar localizacao atual do usuario
        if let coordinate = manager.location?.coordinate{
            
            //Configura a localizacao do Usuario
            self.userLocation = coordinate
            
            if uberIncoming == true{
                
                self.showDriverMessage()
            }
            else{
                
                let region = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: 200, longitudinalMeters: 200) //setando a localizacao do usuario no mapa, os dois segundos parametros da função são o "Range", o campo de visao do mapa
                
                map.setRegion(region, animated: true) //setando regiao
                
//                //Cria uma anotacao para local do usuario
//                let userAnnotation = MKPointAnnotation()
//                userAnnotation.coordinate = coordinate
//                userAnnotation.title = "Seu Local"
//                map.addAnnotation(userAnnotation)
            }
            
            
        }
        
    }
    //Chamar um Uber
    @IBAction func callUber(_ sender: Any) {
        
        let database = Database.database().reference()
        
        //Criando Estrutura no Firebase
        let request = database.child("requisicao") //Nó Raiz
        
        //Recuperar email do usuario logado
        let auth = Auth.auth()
        if let userEmail = auth.currentUser?.email{
            
            if uberCalled == true{ //Uber esta em processo de chamamento    x
                
                //Alterna para o botão chamar
                self.switchButtonCallUber()
                
                //Remover requisicao
                request.queryOrdered(byChild: "email").queryEqual(toValue: userEmail) //Filtrando a requiscao por email e depois especificamente pelo email do usuario que fez a requisicao
                
                    .observeSingleEvent(of: .childAdded) { (snapshot) in
                        
                        snapshot.ref.removeValue() //. ref recupera os dados do usuario selecionado (filtrado) e remove
                    }
                
            }
            else{ //Uber nao esta em processo de chamamento
                
                self.saveRequest()
                
            }
            
        }
        
        
    }
    func saveRequest (){
        
        let database = Database.database().reference()
        
        //Recuperar email do usuario logado
        let auth = Auth.auth()
        
        //Criando Estrutura no Firebase
        let request = database.child("requisicao") //Nó Raiz
        
        if let userId = auth.currentUser?.uid{
            if let userEmail = auth.currentUser?.email{
                if let destinationAdress = self.destinationTxtField.text{
                    if destinationAdress != "" {
                        
                        //Metodo para recuperar localizacao do usario em forma de string
                        CLGeocoder().geocodeAddressString(destinationAdress) { (local , erro) in
                            if erro == nil {
                                if let localData = local?.first{ //Recuperando dados do local do usuario
                                    
                                    //Capturando os dados desejados
                                    var rua = ""
                                    if localData.thoroughfare != nil{
                                        rua = localData.thoroughfare!
                                    }
                                    
                                    var numero = ""
                                    if localData.subThoroughfare != nil{
                                        numero = localData.subThoroughfare!
                                    }
                                    
                                    var bairro = ""
                                    if localData.subLocality != nil{
                                        bairro = localData.subLocality!
                                    }
                                    
                                    var cidade = ""
                                    if localData.locality != nil{
                                        cidade = localData.locality!
                                    }
                                    
                                    var cep = ""
                                    if localData.postalCode != nil{
                                        cep = localData.postalCode!
                                    }
                                    
                                    let completeAdress = "\(rua), \(numero), \(bairro), \(cidade) - \(cep) "
                                    
                                    if let latDest = localData.location?.coordinate.latitude{
                                        if let longDest = localData.location?.coordinate.longitude{
                                            
                                            //Cria alerta para o usuario confirmar o endereco
                                            let alert = UIAlertController(title: "Confirme seu endereço!", message: completeAdress, preferredStyle: .alert)
                                            let actionCancell = UIAlertAction(title: "Cancelar", style: .destructive, handler: nil)
                                            let actionConfirm = UIAlertAction(title: "Confirmar", style: .default , handler: { (alertAction) in
                                                
                                                //Recuperar o nome do usuario
                                                let database = Database.database().reference()
                                                let users = database.child("usuarios").child(userId)
                                                
                                                users.observeSingleEvent(of: .value) { (snapshot) in
                                                    
                                                    let data = snapshot.value as? NSDictionary
                                                    let username = data!["nome"] as? String
                                                    
                                                    //Altera para o botao cancelar
                                                    self.switchButtonCancellUber()
                                                    
                                                    //Criar Requisicao
                                                    let userInfos = [
                                                        "destinoLatitude" : latDest,
                                                        "destinoLongitude" : longDest,
                                                        "email" : userEmail ,
                                                        "nome": username,
                                                        "latitude": self.userLocation.latitude,
                                                        "longitude": self.userLocation.longitude
                                                    ] as [String : Any]
                                                    
                                                    request.childByAutoId().setValue(userInfos) //Criando Nó com id automatico para ser as Requisicoes do Usuario  e setando valores nele
                                                    
                                                    self.switchButtonCancellUber()
                                                }
                                                
                                            }) //fim actionConfirm
                                            
                                            //Atribuindo e mostrando alertas
                                            alert.addAction(actionConfirm)
                                            alert.addAction(actionCancell)
                                            self.present(alert, animated: true, completion: nil)
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                else{
                    print("Endereco nao digitado")
                }

                }
              
            }//fim if email do usuario
        }//fim if id do usuario
        
   
    }
    func switchButtonStartedTrip(){
        self.buttonCallUber.setTitle("Em viagem", for: .normal)
        self.buttonCallUber.isEnabled = false
        self.buttonCallUber.backgroundColor = UIColor(displayP3Red: 0.502, green: 0.502, blue: 0.502, alpha: 1)
        
    }
    
    func switchButtonCallUber(){
        
        self.buttonCallUber.setTitle("Chamar Uber", for: .normal)
        self.buttonCallUber.backgroundColor = UIColor(displayP3Red: 0.067, green: 0.576, blue: 0.604, alpha: 1)
        self.uberCalled = false
    }
    
    func switchButtonCancellUber(){
        
        self.buttonCallUber.setTitle("Cancelar Uber", for: .normal)
        self.buttonCallUber.backgroundColor = UIColor(displayP3Red: 0.873, green: 0.245, blue: 0.353, alpha: 1)
        self.uberCalled = true
    }
    
    
    
}
