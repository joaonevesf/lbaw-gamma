@if ((isset($checkUser) && $checkUser !== $user->username) || !isset($checkUser))
<article class="notification-card mb-1 p-4 border shadow-md flex rounded-md md:flex-row sm:flex-col justify-center align-middle space-x-2 border-b-2 text-base {{$notification->read ? 'read-notification' : ''}}">
    <img class="rounded-full w-10 h-10" src="{{$user->getProfileImage('small')}}" alt="{{$user->username}}'s Profile Image">
    <p>
        <a href="/users/{{$user->username}}">{{$user->username}}</a> {{$notification->verb()}} {{$date}}
    </p>
</article>
@endif

