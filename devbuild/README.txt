NETSNIPE - PROSTY TUTORIAL DLA MNIE
===================================

Ten folder sluzy tylko do budowania gotowych plikow NetSnipe.
Nie musisz wpisywac komend w PowerShellu. Wystarczy kliknac odpowiedni plik .bat.


NAJPROSTSZA OPCJA
------------------

Kliknij:

    BUILD-ALL.bat

To zbuduje wszystko naraz:

    1. portable ZIP
    2. installer EXE

Po zakonczeniu otworzy sie folder artifacts.


CO WYSYLAC UZYTKOWNIKOWI
-------------------------

Najlepszy plik dla zwyklego uzytkownika:

    artifacts\installer\NetSnipe-Setup-win-x64.exe

Uzytkownik uruchamia ten plik, klika instalacje i korzysta ze skrotu na pulpicie.


WERSJA BEZ INSTALACJI
---------------------

Kliknij:

    BUILD-PORTABLE.bat

Powstanie plik:

    artifacts\NetSnipe-Portable-win-x64.zip

Rozpakuj ZIP i uruchom w srodku:

    NetSnipe.exe

Tej wersji uzywa sie wtedy, gdy nie chcesz instalowac programu.


SAM INSTALATOR EXE
------------------

Kliknij:

    BUILD-INSTALLER.bat

Powstanie:

    artifacts\installer\NetSnipe-Setup-win-x64.exe

To jest plik instalacyjny. Nie myl go z plikiem NetSnipe.exe w wersji portable.


ROZNICA W JEDNYM ZDANIU
-----------------------

    Setup EXE  = instaluje program i tworzy skroty.
    Portable    = rozpakowujesz ZIP i uruchamiasz bez instalacji.


JESLI BUILD NIE DZIALA
----------------------

Przed pierwszym budowaniem uruchom z glownego folderu projektu:

    setup-dev.bat

Do budowania potrzebne sa:

    - Windows 10 lub 11 x64
    - .NET 8 SDK
    - Node.js i npm
    - Inno Setup 6 dla instalatora

Nie usuwaj folderu artifacts przed skopiowaniem gotowego pliku.
Folder artifacts jest generowany automatycznie i moze byc nadpisany przy kolejnym buildzie.
