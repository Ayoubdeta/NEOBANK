document.addEventListener("DOMContentLoaded", function () {
    // URL del web service
    const url = `http://ws.mybizum.com:8080/ws.php?action=lista_usuarios`;

    // Instancia clsAjax
    const ajax = new clsAjax(url, null);
    ajax.Call();

    // Esperar la respuesta XML
    document.addEventListener("_CALL_RETURNED_", function () {
        const response = ajax.xml.trim();
        const contactosDiv = document.getElementById("listacontactos");

        if (!contactosDiv) return;

        if (!response) {
            contactosDiv.innerHTML = `<p class="error">No se recibió respuesta del servidor.</p>`;
            return;
        }

        const parser = new DOMParser();
        const xmlDoc = parser.parseFromString(response, "text/xml");

        const error = xmlDoc.querySelector("Error");
        if (error) {
            contactosDiv.innerHTML = `<p class="error">Error: ${error.textContent}</p>`;
            return;
        }

        const users = xmlDoc.getElementsByTagName("User");
        if (users.length === 0) {
            contactosDiv.innerHTML = `<p>No hay contactos disponibles.</p>`;
            return;
        }

        // Crear y llenar la lista de usuarios
        const ul = document.createElement("ul");
        ul.classList.add("lista-contactos");

        for (let i = 0; i < users.length; i++) {
            const userName = users[i].getElementsByTagName("USERNAME")[0].textContent;

            const li = document.createElement("li");
            li.textContent = userName;

            // Al hacer clic, se llena el campo "receiver"
            li.addEventListener("click", () => {
                document.getElementById("receiver").value = userName;
            });

            ul.appendChild(li);
        }

        contactosDiv.innerHTML = "";
        contactosDiv.appendChild(ul);
    });
});
