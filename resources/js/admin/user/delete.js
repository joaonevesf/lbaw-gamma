import { configureConfirmationForm, populateModalText } from "../../components/confirmation_modal";

const confirmationModal = document.getElementById("confirmation-modal");

export function deleteUserAction(deleteConfirmationTriggerButton) {
    const username = deleteConfirmationTriggerButton.parentElement.parentElement.getAttribute("data-username");
    const profileImage = deleteConfirmationTriggerButton.parentElement.parentElement.getAttribute("data-user-image");

    populateModalText(`
            <div class="flex flex-col align-middle">
                <img class="center rounded-full w-10 h-10" src="${profileImage}" />
                <p>Are you sure you want to delete <a class="hover:underline" href="/users/${username}">${username}</a>?</p>
            </div>
        `);
    configureConfirmationForm(`/users/${username}`, "DELETE", "delete_user", "bg-red-500", "text-red-500");
    confirmationModal.classList.remove("hidden");
}