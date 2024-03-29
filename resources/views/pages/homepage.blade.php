@extends('layouts.head')

<head>
    @vite(['resources/css/app.css', 'resources/js/search/feed/scroll.js', 'resources/js/components/snackbar.js'])

    <title>{{ config('app.name', 'Laravel') }} | {{ucfirst($feed)}} feed</title>
    
    @php
        $url = Request::url();
        $logo = config('app.url', $url) . "/public/logo.png";
        $title = "Gamma | " . ucfirst($feed) . " feed";
    @endphp

    @include('partials.head.ogtags', [
    'title' => $title,
    'url' => $url,
    'image' => $logo
    ])


    <link href="{{ url('css/post.css') }}" rel="stylesheet">
</head>

@include('partials.navbar')

<main class="center md:mb-12">
    @can('create', App\Models\Post::class)
    <a href="{{ route('post.createForm') }}" class="my-4 block mx-auto px-4 py-2 form-button text-center rounded hover:no-underline">Create Post</a>
    @endcan
    <ul class="tab-container center justify-center flex border border-black rounded shadow my-4">
        <li class="flex w-1/2 {{ $feed === 'popular' ? 'border-t-4 border-black' : '' }} p-2 justify-center">
            <a href="/feed" class="hover:underline">Popular</a>
        </li>

        @auth
        <li class="flex w-1/2 {{ $feed === 'personal' ? 'border-t-4 border-black' : '' }} p-2 justify-center">
            <a href="/feed/personal" class="hover:underline">Personalized</a>
        </li>
        @endauth
    </ul>

    @if($email_verified)
    @if(count($posts) == 0)
    <p class="text-center">No posts found.</p>
    @else
    <div id="posts">
        @for($i = 0; $i < count($posts); $i++) @include('partials.post_card', ['post'=> $posts[$i], 'preview' => false])
            @endfor
            @endif
            @else
            @include('partials.auth.email_validation_notice_text')
            @endif
    </div>
</main>

@include('partials.snackbar')

@include('partials.footer')
