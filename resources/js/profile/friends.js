window.addEventListener("DOMContentLoaded", (event) => {
    const form = document.getElementById("friendForm");
    if (form) {
        const button = form.querySelector("button");
        let methodField = form.attributes["data-method"];
        const username = document.getElementById("username").value;
        button.addEventListener("click", (e) => {
            e.preventDefault();
            console.log(form.action);
            console.log(methodField.value);
            fetch(form.action, {
                method: methodField.value,
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-TOKEN": document
                        .querySelector('meta[name="csrf-token"]')
                        .getAttribute("content"),
                },
            })
                .then((response) => {
                    if (response.ok) {
                        // Update the button text based on the action
                        if (methodField.value.toUpperCase() === "POST") {
                            button.textContent = "Cancel Friend Request";
                            methodField.value = "DELETE";
                        } else if (
                            methodField.value.toUpperCase() === "DELETE"
                        ) {
                            button.textContent = "Add Friend";
                            methodField.value = "POST";
                            form.action = `/api/users/${username.value}/friends/requests`;
                        }
                    }
                })
                .catch((error) => {
                    console.log(error);
                });
        });
    }
});
