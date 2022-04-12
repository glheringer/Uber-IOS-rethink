//
//  ViewController.swift
//  Uber
//
//  Created by Rethink on 31/03/22.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class ViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let auth = Auth.auth()

        auth.addStateDidChangeListener { (auth, user) in //ouvinte para verificar se o usuario ja esta logado e redirecionar à tela principal, na verdade ele fica verificando constantemente se houve alguma alteracao no estado de autenticacao do usuario
            
            if  user != nil {
                let database = Database.database().reference()
                let users = database.child("usuarios").child(user!.uid)
                
                users.observeSingleEvent(of: .value) { (snapshot) in
                  
                    let data = snapshot.value as? NSDictionary //recuperar dicionario com dados dos usuarios
                    if data != nil {
                     
                        let userType = data!["tipo"] as! String //recuperar tipo do usuario logado no dicionario de usuarios

                        //Comparar tipo do usuario
                        if userType == "passageiro"{
                            
                            self.performSegue(withIdentifier: "autoLoginSegue", sender: nil)
                        }
                        else{
                            
                            self.performSegue(withIdentifier: "driverAutoLoginSegue", sender: nil)
                        }

                    }
        
                }
       
            }
            else{
                print("Entre novamente.")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

