<?php

class UserManager {
    private $dbCommand;

    public function __construct($dbCommand) {
        $this->dbCommand = $dbCommand;
    }

        public function register($username, $name, $lastname, $password, $email, $gender, $def_lang): void {
            
            if (empty($username) || empty($name) || empty($lastname) || empty($password) || empty($email) || empty($gender) || empty($def_lang)) {
                
            } else {
                try {
                    
                    $result = $this->dbCommand->execute('sp_user_register', array($username, $name, $lastname, $password, $email, $gender, $def_lang));
        
                    
                    $register_code = $this->dbCommand->execute('sp_wdev_get_registercode', array($username, 0));
        
                    
                    $url = 'https://script.google.com/macros/s/AKfycby5Rwbbrm8qeSdWw8Lq034jnLAgHR1DWr1Tesy3Fgnmbn9cMp3VtfU-k2s6ghAgSxn0Pg/exec';
                    
                    
                    $destinatario = $email;
                    $asunto = 'Código de registro.';
                    $cuerpo = $name . ', su código de verificación es ' . $register_code;
                    $adjunto = null;
        
                   
                    $resultado = enviarCorreo($url, $destinatario, $asunto, $cuerpo, $adjunto);
        
                    
                    header('Content-Type: text/xml');
        
                    
                    echo $result;
                } catch (PDOException $e) {
                    echo 'Error: ' . $e->getMessage();
                }
            }
        }
    public function checkPasswordStrength($password): string {
    try {
        $xmlResponse = $this->dbCommand->execute('sp_check_password_strength', array($password));

        if ($xmlResponse) {
            $xml = simplexml_load_string($xmlResponse);
            return (string) $xml->Message;
        } else {
            return "Error al verificar la contraseña.";
        }

    } catch (Exception $e) {
        return "Error al ejecutar el procedimiento almacenado: " . $e->getMessage();
    }
}

    public function login($username, $password): void {
        if (empty($username) || empty($password)) {
            echo "Todos los campos son obligatorios.";
        } else {
            try {
                $result = $this->dbCommand->execute('sp_user_login', array($username, $password));
                $_SESSION['username'] = $username;
                setcookie("logged_in_user", $username, time() + (86400 * 30), "/");
                
                header('Content-Type: text/xml');

                
                echo $result;
            } catch (PDOException $e) {
                echo 'Error: ' . $e->getMessage();
            }
        }
    }
    
    public function logout($username): void {
        try {
            if (!empty($username)) { 
                
                $result = $this->dbCommand->execute('sp_user_logout', array($username));

                
                header('Content-Type: text/xml');

                
                echo $result;
            }
        } catch (PDOException $e) {
            echo 'Error: ' . $e->getMessage();
        }
    }

    public function changePassword($username, $password, $newpassword): void {
        if (empty($username) || empty($password)) {
            echo "Todos los campos son obligatorios.";
        } else {
            try {
                $result = $this->dbCommand->execute('sp_user_change_password', array($username, $password, $newpassword));

                
                header('Content-Type: text/xml');

                
                echo $result;
            } catch (PDOException $e) {
                echo 'Error: ' . $e->getMessage();
            }
        }
    }
    
    public function accountValidate($username, $code){
        if (empty($username) || empty($code)){
            echo "Todos los campos son obligatorios.";
        } else {
            try {
                $result = $this->dbCommand->execute('sp_user_accountvalidate', array($username, $code));

                
                header('Content-Type: text/xml');

                
                echo $result;
                
            } catch (PDOException $e) {
                echo 'Error: ' . $e->getMessage();
            }
        }
    }
    

    public function listusers($ssid): void{
        if (empty($ssid)){
            echo "Todos los campos son obligatorios.";
        } else {
            try {
                $result = $this->dbCommand->execute('sp_list_users2', array($ssid));

                
                header('Content-Type: text/xml');

                
                echo $result;
                
            } catch (PDOException $e) {
                echo 'Error: ' . $e->getMessage();
            }
        }
    }
    








    
}

?>