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
    var uberCalled = false
    
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
        
    }
    
    //Configurar Localizacao do Usuario
    func configUserLocation(){
        
        self.map.delegate = self
        locationManager.delegate = self //Delegando a propria classe para controlar o gerenciador de localizacao
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //Melhor atualizacao de localizacao do usuario
        locationManager.requestWhenInUseAuthorization() //Pedir ao usuario permissao para autorizacao enquanto usa
        locationManager.startUpdatingLocation() //Comecar a coletar localizacao do usuario
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { //Metodo para atualizar localizacao do usuario, a cada mudanca ele recupera a localizacao do usuario
        
        //Recuperar localizacao atual do usuario
        if let coordinate = manager.location?.coordinate{
            
            //Configura a localizacao do Usuario
            self.userLocation = coordinate
            
            let region = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: 200, longitudinalMeters: 200) //setando a localizacao do usuario no mapa, os dois segundos parametros da função são o "Range", o campo de visao do mapa
            
            map.setRegion(region, animated: true) //setando regiao
            
            
//            /* Criar uma Anotação para local do usuario, não sei para que*/
//
//            //Antes de executar a criacao da anotacao de local, apagar as indesejadas geradas pela atualizacao do app
//            map.removeAnnotations(map.annotations)
//            //Criar uma Anotação
//            let userLocationAnnotation = MKPointAnnotation()
//            userLocationAnnotation.coordinate = coordinate
//            userLocationAnnotation.title = "Seu local"
//
//            map.addAnnotation(userLocationAnnotation)
            
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
                
                //Altera para o botao cancelar
                self.switchButtonCancellUber()
                
                //Criar Requisicao
                let userInfos = [
                    "email" : userEmail ,
                    "nome": "Guilherme Heringer",
                    "latitude": userLocation.latitude,
                    "longitude": userLocation.longitude
                ] as [String : Any]
                
                request.childByAutoId().setValue(userInfos) //Criando Nó com id automatico para ser as Requisicoes do Usuario  e setando valores nele
            }
            
        }
        
        
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
