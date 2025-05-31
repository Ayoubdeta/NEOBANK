<?php
header("Access-Control-Allow-Origin: http://mybizum.com:8080");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

session_start();

require_once 'utils/dbo/daoConnect.php';
require_once 'utils/dbo/daoCommand.php';
require_once 'utils/mailtools/mail_sender.php';
require_once 'security/clsUserManager.php';
require_once 'utils/dbo/daoManager.php';
require_once 'bizum/clsTransaction.php';
require_once 'bizum/clsBlock.php';
require_once 'bizum/clsBlockchain.php';
require_once 'bizum/clsBizum.php';




// Función para verificar la fortaleza de la contraseña
/*
function checkPasswordStrength($password, $pdoObject): string {


    try {
        // Preparar la consulta para ejecutar el procedimiento almacenado
        $sql = "EXEC sp_check_password_strength @PASSWORD = :password";
        $stmt = $pdoObject->prepare($sql);

        // Enviar la contraseña como parámetro
        $stmt->bindParam(':password', $password, PDO::PARAM_STR);

        // Ejecutar la consulta
        $stmt->execute();

        // Obtener el resultado (que debe ser XML)
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        // Verificar si se obtuvo alguna fila y si la clave 'PasswordStrength' está definida
        if ($row && isset($row['PasswordStrength'])) {
            $xmlResponse = $row['PasswordStrength'];

            // Cargar el XML en un objeto SimpleXMLElement
            $xml = simplexml_load_string($xmlResponse);

            // Verificar si la contraseña es fuerte o débil
            return (string)$xml->Message;
        } else {
            return "Error al verificar la contraseña.";
        }
    } catch (Exception $e) {
        return "Error al ejecutar el procedimiento almacenado: " . $e->getMessage();
    }
}
*/

function checkPasswordStrength($password, DBCommand $dbCommand): string {
    try {
        // Ejecutar el procedimiento almacenado usando DBCommand
        $xmlResponse = $dbCommand->execute('sp_check_password_strength', array($password));

        if ($xmlResponse) {
            // Cargar el XML
            $xml = simplexml_load_string($xmlResponse);

            // Devolver el mensaje desde el XML
            return (string) $xml->Message;
        } else {
            return "Error al verificar la contraseña.";
        }

    } catch (Exception $e) {
        return "Error al ejecutar el procedimiento almacenado: " . $e->getMessage();
    }
}


    




// //Conexion sql server
$connection = new DBConnection('172.17.0.3,1433', 'PP_DDBB', 'sa', 'Password2!');


$pdoObject = $connection->getPDOObject();

// Crear una instancia de DBCommand pasando el objeto PDO
$dbCommand = new DBCommand($pdoObject);

// $dbCommand = new DBCommand($pdoObject);

// Crear instancias de los gestores de usuario y base de datos
$userManager = new UserManager($dbCommand);
$dbManager = new DBManager($dbCommand);


// Crear una nueva blockchain pasando el DBCommand
$myBlockchain = new Blockchain($dbCommand);



$action = isset($_GET['action']) ? $_GET['action'] : '';

if (empty($action)) {
    //echo "Accion no especificada.";
} else {
    switch ($action) {
        case "register":
            // Verificar si la contraseña está presente
            if (isset($_GET['password'])) {
                $password = $_GET['password'];
                $username = $_GET['username'];
                $name = $_GET['name'];
                $lastname = $_GET['lastname'];
                $email = $_GET['email'];
                $gender = $_GET['gender'];
                $def_lang = $_GET['def_lang'];
        
                // Verificar la fortaleza de la contraseña
                //$passwordStrength = checkPasswordStrength($password, $pdoObject);
                //$passwordStrength = checkPasswordStrength($password, $pdoObject);
                $passwordStrength = checkPasswordStrength($password, $dbCommand);
                if ($passwordStrength == 'Contraseña fuerte') {
                    // Continuar con el registro si la contraseña es fuerte
                    $userManager->register($username, $name, $lastname, $password, $email, $gender, $def_lang);
                    //echo "Registro exitoso";
                } else {
                    // Mostrar mensaje si la contraseña es débil
                    echo "La contraseña es débil: " .  $passwordStrength; 
                }
            } else {
                //echo "Por favor, ingresa una contraseña válida para verificar.";
            }
            break;
        case "login":
            $userManager->login($_GET['username'], $_GET['password']);
            
            break;
        case "logout":
            $userManager->logout($_GET['username']);
            break;
        case "changepass":
            // Verificar si la contraseña y la nueva contraseña están presentes
            if (isset($_GET['password']) && isset($_GET['newpassword'])) {
                    $password = $_GET['password'];
                    $newPassword = $_GET['newpassword'];
            
                    // Verificar la fortaleza de la contraseña actual
                    //$passwordStrength = checkPasswordStrength($password, $pdoObject);
                    $passwordStrength = checkPasswordStrength($password, $dbCommand);
            
                    if ($passwordStrength == 'Contraseña fuerte') {
                        // Verificar también la fortaleza de la nueva contraseña
                        //$newPasswordStrength = checkPasswordStrength($newPassword, $pdoObject);
                        $newPasswordStrength = checkPasswordStrength($newPassword, $dbCommand);
                        if ($newPasswordStrength == 'Contraseña fuerte') {
                            // Continuar con el cambio de contraseña si ambas contraseñas son fuertes
                            $userManager->changePassword($_GET['username'], $password, $newPassword);
                        } else {
                            // Mostrar mensaje si la nueva contraseña es débil
                            echo "La nueva contraseña es débil: " . $newPasswordStrength;
                        }
                    } else {
                        // Mostrar mensaje si la contraseña actual es débil
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
                // Verificar si los parámetros GET están presentes
                if (isset($_GET['sender'], $_GET['receiver'], $_GET['amount'])) {
                    $sender = $_GET['sender'];
                    $receiver = $_GET['receiver'];
                    $amount = $_GET['amount'];
                } else {
                    echo "Faltan parámetros necesarios en la URL.<br>";
                    exit();
                }
                
                $myBlockchain = new Blockchain($dbCommand);
                $tx1 = new Transaction($sender, $receiver, $amount);
                $block1 = new Block(1, time(), [$tx1]); // Transacción en array
                $myBlockchain->addBlock($block1);
                try {
                    if ($myBlockchain->isChainValid()) {
                        // Guardar los bloques en la base de datos
                        $block1->saveSQL();  // Guardar bloque 1
        
                        // Imprimir la blockchain en formato JSON bonito
                        print_r($myBlockchain);
                        echo "</pre>";
                    } else {
                        echo 'La blockchain no es válida.<br>';
                    }
                } catch (Exception $e) {
                    echo "Error: " . $e->getMessage() . "<br>";
                }
                break;
                
                case "check_balance":
                    $bizum = new clsBizum($dbCommand);
                    // Obtener el nombre de usuario desde la URL
                    $username = isset($_GET['username']) ? $_GET['username'] : '';
                
                    // Asegúrate de que el objeto clsBizum está bien inicializado
                    if (isset($bizum) && $username) {
                        // Ejecutar la consulta para obtener el balance
                        $response = $bizum->checkBalance($username);
                        
                        // Establecer el encabezado de respuesta como XML
                        header("Content-Type: application/xml; charset=UTF-8");
                        
                        // Imprimir la respuesta en formato XML
                        echo $response;
                    } else {
                        echo "No se proporcionó un nombre de usuario válido o no se pudo conectar con Bizum.";
                    }
                    break;
                
        
            
        default:
            echo "Acción no válida.";
            break;
    }




}

// Register: OK
// localhost:40080/gen-web/gen-web/PHP/index.php?action=register&username=polrabascall&name=Pol&lastname=Rabascall&password=Test12345!!&email=polrabascall@gmail.com&gender=Hombre&def_lang=es
// http://localhost:40080/gen-web/PHP/index.php?action=register&username=PauAllendee&name=Pau&lastname=Allende&password=C0ntraseña2004!!&email=pauallendeherraiz@gmail.com&gender=Hombre&def_lang=es
//?action=register&username=aribas&name=Alex&lastname=Rab&password=Test12345!!&email=aribas@gmail.com
// NUEVA URL
// http://localhost:40080/gen-web/PHP/index.php?action=register&username=aribas&name=Alex&lastname=Rab&password=Test12345!!&email=aribas@gmail.com&gender=Hombre&def_lang=es


// Account Validate: OK
// http://localhost:40080/gen-web/gen-web/PHP/index.php?action=accvalidate&username=polrabascall&code=
// http://localhost:40080/gen-web/PHP/index.php?action=accvalidate&username=PauAllendee&code=40381

// Login:  OK
// localhost:40080/gen-web/gen-web/PHP/index.php?action=login&username=polrabascall&password=Test12345!!
// http://localhost:40080/gen-web/PHP/index.php?action=login&username=PauAllendee&password=C0ntraseña2004!!


// Logout: OK 
// localhost:40080/gen-web/gen-web/PHP/index.php?action=logout
// http://localhost:40080/gen-web/PHP/index.php?action=logout

// Change Password: OK 
// localhost:40080/gen-web/gen-web/PHP/index.php?action=changepass&username=polrabascall&password=Test12345!!&newpassword=NewPassword12345!!
// http://localhost:40080/gen-web/PHP/index.php?action=changepass&username=PauAllendee&password=C0ntraseña2004!!&newpassword=NewPassword12345!!

// View Active Connections: OK
// localhost:40080/gen-web/gen-web/PHP/index.php?action=viewcon
// http://localhost:40080/gen-web/PHP/index.php?action=viewcon

// View Historical Connections:  OK
//localhost:40080/gen-web/gen-web/PHP/index.php?action=viewconhist
// http://localhost:40080/gen-web/PHP/index.php?action=viewconhist


// mirar luego
//localhost:40080/gen-web/gen-web/PHP/index.php?action=listusers&ssid=a0b39afe-6971-4d0c-85ca-d63bb5d07de2

?>