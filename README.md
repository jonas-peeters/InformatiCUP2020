# InformatiCUP 2020 Server
von Jonas Peeters

Dies ist eine Einreichung für den InformatiCUP 2020. In dieser ReadMe ist eine Anleitung zur Verwendung. Eine genauere Erklärung, wie der Server arbeitet, ist in `Theorie/Theorie.pdf`.

Da der Server in Swift geschrieben ist, muss dieses entweder installiert sein (Siehe [Installing Swift](https://swift.org/getting-started/#installing-swift)) oder der Server muss in einem Docker Container laufen. ([Get Docker](https://docs.docker.com/get-docker/)).


## Direkt mit Swift starten
Sind Swift und Dependencies (openssl, libssl-dev, clang, libicu-dev, libcurl4-openssl-dev) installiert, so kann der Server mit den folgenden Befehlen compilliert und gestartet werden:
```shell
    $ swift build -c release
    $ .build/release/InformatiCUP
```

Standardmäßig wird der Server im Predict-Modus gestartet. Das heißt, es kann manuell der Client gestartet werden. Weitere Modi sind "stats" für eine Selbstevaluation des Servers und "train", damit die Neuralen Netzwerke weiter trainiert werden. Achtung: Dabei werden die bestehenden neuralen Netzwerke nach jeder Generation überschrieben. Für die Evaluation bitte die beigefügten Netzwerke verwenden.

Unter Linux muss bei den Modi "stats" und "train" zusätzlich mit `-c` der Pfad zur Linux Version des Clients in `binaries/ic20_linux` angegeben werden.

Für weitere Optionen siehe die Hilfe mit `--help`. Diese Hilfe ist auch am Ende dieses Dokumentes zu finden.


## Docker
Ist Docker installiert und gestartet, so kann mit den folgenden Befehle ein Docker-Image erstellt und gestartet werden:
```shell
    $ docker build -t ic20 .
    $ docker run --name ic20 ic20
```

Zum Beenden und Entfernen des Containers können die folgenden Befehele verwendet werden:
```shell
    $ docker stop ic20
    $ docker rm ic20
```

Standardmäßig wird der Server im Predict-Modus gestartet. Das heißt, es kann manuell der Client gestartet werden. Weitere Modi sind "stats" für eine Selbstevaluation des Servers und "train", damit die Neuralen Netzwerke weiter trainiert werden. Bei Verwendung von Docker kann dazu der `run`-Befehl wie folgt abgeändert werden:
```shell
    $ docker run --name ic20 ic20 .build/release/InformatiCUP [args] 
```
Wenn die Modi "stats" oder "train" verwendet werden, muss mit `-c /app/binaries/ic20_linux` die Linux Version des Clients angegeben werden!

Für die Hilfe kann dementsprechend der folgende Befehl genutzt werden. Die Hilfe ist aber auch zusätzlich am Ende dieses Dokumentes beigefügt.
```shell
    $ docker run ic20 .build/release/InformatiCUP --help
```

Da innerhalb von Docker die Threadpriorisierung scheinbar nicht zuverlässig läuft, wird die Statusanzeige nur unregelmäßig aktualisiert.

## Hilfe (Englisch)

    Usage: ./InformatiCUP [arguments]

    The following arguments are available:
      --mode, -m:   Set the mode of the server to (train|predict|
                    stats). [Default: predict]

      --client, -c: Path to the InformatiCUP client. Required for
                    predict mode. [Default: ./binaries/ic20_darwin]

      --help, -h:   Show this help

      --mutations:  The number of mutations that are created per
                    generation. [Default: 30]

      --games:      Depends on mode:
                    Training: The number of rounds each mutation
                         plays per generation. [Default: 15]
                    Statistics: The number of games that will be
                         played to generate statistics. [Default: 50]

      --force-cpu:  Force the usage of the CPU engine even if a GPU
                    is available. [Default: Disabled]

    Additional information:
    (1): In training and stat mode the program automatically starts
         instances of the client for training. You do not have to
         start them manually
    (2): In the prediction mode -c is ignored. The client is not
         started automatically. You have to start them manually. The
         port is 50123.
