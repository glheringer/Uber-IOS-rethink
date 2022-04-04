//
//  SignInViewController.swift
//  Uber
//
//  Created by Rethink on 31/03/22.
//

import UIKit
import FirebaseAuth

class SignInViewController: UIViewController {


    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBAction func userLogin(_ sender: Any) {
        
        let text = self.validateText() //chamando a funcao validar e imprimindo mensagem caso o usuario tenha deixado algum campo vazio
        if text == "" {  // caso o usuario tenha digitado todos os campos
            
            //Verificar mais uma vez se os campos estao devidamente preenchidos
            if let email = self.email.text{
                if let password = self.password.text{
                    
                    //Fazer autenticacao do usuario (Login)
                    Auth.auth().signIn(withEmail: email, password: password) { (user, erro) in //verifica os dados e realiza login
                        
                        if erro == nil{ //Após nao ter erro, sucesso ao logar entao encaminha o usuaria à tela principal do sistema
                            
                            /* Valida se o usuario esta logado
                                Caso o usuario esteja logado, sera redirecionado automaticamente de acordo com o tipo de usuario
                                com o evento criado na ViewController*/
                           
                            if user == nil {
                                
                                //Exibindo alerta com a mensagem do erro
                                print("Erro ao autenticar usuario")
                                
                            }

                        }
                        else{
                            
                            //Exibindo alerta com a mensagem do erro
                            print("Erro  ao logar usuario")
                            
                        }
                    }
                    
                }
            }
        }
        
        else{
            print("O campo \(text) não foi preenchido")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    func validateText() -> String { //Validar se todos os campos foram preenchidos devidamente
        if(self.email.text?.isEmpty)!{
            return "E-mail"
        }
        else if (self.password.text?.isEmpty)!{
            return "Senha"
        }
       return ""
    }
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

  
}
