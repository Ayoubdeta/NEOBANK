<?php
header("Access-Control-Allow-Origin: http://mybizum.com:8080");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

session_start();

require_once 'com/utils/dbo/daoConnect.php';
require_once 'com/utils/dbo/daoCommand.php';
require_once 'com/utils/mailtools/mail_sender.php';
require_once 'com/security/clsUserManager.php';
require_once 'com/utils/dbo/daoManager.php';
require_once 'com/blockchain/clsTransaction.php';
require_once 'com/blockchain/clsBlock.php';
require_once 'com/blockchain/clsBlockchain.php';
require_once 'com/bizum/clsBizum.php';




$connection = new DBConnection('172.17.0.3,1433', 'PP_DDBB', 'sa', 'Password2!');


$pdoObject = $connection->getPDOObject();

$dbCommand = new DBCommand($pdoObject);


$userManager = new UserManager($dbCommand);
$dbManager = new DBManager($dbCommand);


$myBlockchain = new Blockchain($dbCommand);

$bizum = new clsBizum($dbCommand);



$action = isset($_GET['action']) ? $_GET['action'] : '';

if (empty($action)) {
   
} else {
    switch ($action) {
        case "register":
           
            if (isset($_GET['password'])) {
                $password = $_GET['password'];
                $username = $_GET['username'];
                $name = $_GET['name'];
                $lastname = $_GET['lastname'];
                $email = $_GET['email'];
                $gender = $_GET['gender'];
                $def_lang = $_GET['def_lang'];
        
                
                
                $passwordStrength = $userManager->checkPasswordStrength($password);
                if ($passwordStrength == 'Contraseña fuerte') {
                    
                    $userManager->register($username, $name, $lastname, $password, $email, $gender, $def_lang);
                    //echo "Registro exitoso";
                } else {
                    
                    echo "La contraseña es débil: " .  $passwordStrength; 
                }
            } else {
                
            }
            break;
        case "login":
            $userManager->login($_GET['username'], $_GET['password']);
            
            break;
        case "logout":
            $userManager->logout($_GET['ssid']);
            break;
        case "changepass":
            if (isset($_GET['password']) && isset($_GET['newpassword'])) {
                    $password = $_GET['password'];
                    $newPassword = $_GET['newpassword'];
            
                    $passwordStrength = $userManager->checkPasswordStrength($password);
                    if ($passwordStrength == 'Contraseña fuerte') {
                        
                        $newPasswordStrength = $userManager->checkPasswordStrength($newPassword);
                        if ($newPasswordStrength == 'Contraseña fuerte') {
                            
                            $userManager->changePassword($_GET['username'], $password, $newPassword);
                        } else {
                            // Mostrar mensaje si la nueva contraseña es débil
                            echo "La nueva contraseña es débil: " . $newPasswordStrength;
                        }
                    } else {
                        
                        echo "La contraseña actual es débil: " . $passwordStrength;
                    }
            } else {
                echo "Por favor, ingresa una contraseña válida para verificar y una nueva contraseña para cambiar.";
            }                break;
        case "viewcon":
            $dbManager->viewConnections();
            break;
        case "viewconhist":
            $dbManager->viewHistoricConnections();
            break;
        case "accvalidate":
            $userManager->accountValidate($_GET['username'],$_GET['code']);
            break;
        case "listusers":
            $userManager->listusers($_GET['ssid']);
            break;                    
        case 'bizum':
            header("Content-Type: application/xml; charset=UTF-8");
            $sender = $_GET['sender'] ?? null;
            $receiver = $_GET['receiver'] ?? null;
            $amount = $_GET['amount'] ?? null;

            $bizum = new clsBizum($dbCommand);
            echo $bizum->enviarBizum($sender, $receiver, $amount);
            break;
            
        case "check_balance":
                   
                    $connectionId = isset($_GET['ConnectionId']) ? $_GET['ConnectionId'] : '';
                    if (isset($bizum) && $connectionId) {
                        $response = $bizum->checkBalance($connectionId);
                        
                        header("Content-Type: application/xml; charset=UTF-8");

                        echo $response;
                    } else {
                        echo "No se proporcionó un nombre de usuario válido o no se pudo conectar con Bizum.";
                    }
                break;
                
                case "get_transactions":
                    
                    $ssid = isset($_GET['ssid']) ? $_GET['ssid'] : '';

                    
                    if (!$ssid) {
                        http_response_code(400); 
                        echo "Missing 'username' parameter.";
                        break;
                    }

                
                    $xml = $bizum->getTransactionsHistory($ssid);

                    header("Content-Type: application/xml; charset=UTF-8");
                    echo $xml;
                break;
                case "get_last_transactions":
                    $ssid = isset($_GET['ssid']) ? $_GET['ssid'] : '';
                    $xml = $bizum->getLastTransactions($ssid);
                    echo $xml;
                break;
                case "lista_usuarios":
                    $xml = $bizum->getActiveUsernames();
                    echo $xml;
                break;

            
        default:
            echo "Acción no válida.";
            break;
    }




}

?>