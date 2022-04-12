//
//  RegisterViewController.swift
//  Uber
//
//  Created by Rethink on 31/03/22.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class RegisterViewController: UIViewController {

    @IBOutlet weak var `switch`: UISwitch!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var email: UITextField!
    
    @IBAction func register(_ sender: Any) {
        let text = self.validateText() //chamando a funcao validar e imprimindo mensagem caso o usuario tenha deixado algum campo vazio
        if text == "" {  // caso o usuario tenha digitado todos os campos
        
            //Criar usuario
            let auth = Auth.auth()
            
            //Verificar mais uma vez se os campos estao devidamente preenchidos
            if let email = self.email.text{
                if let password = self.password.text{
                    if let name = self.name.text{
                        
                        //Criando o usuario
                        auth.createUser(withEmail: email, password: password) { (user,erro) in //Criar usuario no banco
                            if erro == nil {
                                
                                //Verifica o tipo do usuario
                                 var userType = ""
                                if self.switch.isOn { //Vericando caso o switch esteja ativo ou nao
                                    userType = "passageiro"
                                }
                                else{
                                    userType = "motorista"
                                }
                                
                                //Configura banco de dados
                                let database = Database.database().reference()
                                let users = database.child("usuarios")
                                
                                //Validando se o usuario foi autenticado
                                if user != nil{
                                    let userData = [ //setando dados do usuario
                                        "email": email,
                                        "nome": name,
                                        "tipo": userType
                                    ] as [ String : Any ]
                                   
                                    users.child((user?.user.uid)!).setValue(userData) //Criando nó com id gerado para usuario cadastrado e setando dados desse usuario, assim o criando
                                }
                                
                                /* Valida se o usuario esta logado
                                    Caso o usuario esteja logado, sera redirecionado automaticamente de acordo com o tipo de usuario
                                    com o evento criado na ViewController*/
                       
                            }
                            else{
                                print("Erro ao criar conta do usuario, tente novamente")
                            }
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
        else if (self.name.text?.isEmpty)!{
            return "Nome completo"
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
