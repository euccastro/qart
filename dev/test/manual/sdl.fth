\ Test SDL init/quit cycle

." Testing SDL init..." CR
SDL_INIT_VIDEO SDL_Init

ASSERT ." SDL init SUCCESS!" CR

S" Titalo" 6 = ASSERT       \ title (NULL - may cause X11 error but we'll handle it)
1024                         \ width
1024                         \ height
SDL_WINDOW_SHOWN            \ flags
SDL_CreateWindow

ASSERT

." Window created! Testing 3000ms delay..." CR
3000 SDL_Delay
." Delay completed!" CR

SDL_DestroyWindow
." Window destroyed" CR

SDL_Quit
." SDL quit completed!" CR

." SDL API test completed!" CR