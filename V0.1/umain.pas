unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Forms,
  Controls,
  Graphics,
  Dialogs,
  ComCtrls,
  StdCtrls,
  ExtCtrls,
  Buttons,
  fphttpclient,
  lcltype,
  lclintf,
  Grids,
  IpHtml,
  opensslsockets,
  fpjson,
  jsonparser,
  zstream;

const
  LARGEUR = 8192;
  HAUTEUR = 4096;

type
  // Définition des lignes de pixels.
  TRGBTriple = packed record
    R, V, B: Byte;
  end;
  TRGBTripleArr = packed array [0..LARGEUR - 1] of TRGBTriple;
  PRGBTripleArr = ^TRGBTripleArr;

  // Définition de la liste des couleurs
  TPalette = array [0..255] of TRGBTriple;
  PPalette = ^TPalette;

  { TfrmPrincipale }
  TfrmPrincipale = class(TForm)
    ComboBox1: TComboBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    gbSelection: TGroupBox;
    imgMonde: TImage;
    hpInformations: TIpHtmlPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Memo1: TMemo;
    pcDetails: TPageControl;
    pcMain: TPageControl;
    pgMenus: TPageControl;
    pbPosition: TPaintBox;
    sbCarte: TScrollBox;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    StatusBar1: TStatusBar;
    StringGrid1: TStringGrid;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    tsInfo: TTabSheet;
    tsMonde: TTabSheet;
    tsPosition: TTabSheet;
    tsAccueil: TTabSheet;
    tsCreation: TTabSheet;
    tsAide: TTabSheet;
    tsFichiers: TTabSheet;
    procedure ComboBox1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure hpInformationsHotClick(Sender: TObject);
    procedure hpInformationsHotURL(Sender: TObject; const URL: String);
    procedure pbPositionPaint(Sender: TObject);
    procedure pbPositionResize(Sender: TObject);
    procedure StringGrid1Click(Sender: TObject);
    procedure StringGrid1Resize(Sender: TObject);
  private
    FS: Single;
    FBMP: TBitmap;
    FLien: string;
    FMonde: array[0..HAUTEUR - 1, 0..LARGEUR - 1] of Byte;
    FCouleurs: TPalette;
    procedure AffichePosition(const ANom: string; const AX, AY: Integer);
    procedure AfficherMonde;
    procedure CreerPalette;
    procedure ChargerListes;
    procedure ChargerMonde;
    function SupprimerAccents(const AValue: string): String;
    function Degrader(const ADepart, AProfondeur: Byte; ACouleur: TColor): Byte;
    function ColorToRVB(const AValue: TColor): TRGBTriple;
    function GetRequete(const AValue: string): string;
  public
    // publique
  end;

var
  frmPrincipale: TfrmPrincipale;

const
  RACINE_URL = 'http://www.atlaspolaris.com';
  DOSSIER_API = '/restful/';

implementation

{$R *.lfm}

{ TfrmPrincipale }

function TfrmPrincipale.ColorToRVB(const AValue: TColor): TRGBTriple;
begin
  // Converti une couleur en son équivalent en RVB
  Result.R := Red(AValue);
  Result.V := Green(AValue);
  Result.B := Blue(AValue);
end;

function TfrmPrincipale.GetRequete(const AValue: string): string;
var
  LClient: TFPHTTPClient;
begin
  // Initialise la réponse.
  Result := '';

  // Création du chargement des données depuis le site
  LClient:= TFPHTTPClient.Create(Self);
  try
    try
      // Télécharge les données depuis le serveur
      Result := LClient.Get(AValue);
    except
      // Intercepte les erreurs possible.
       on E:EHTTPClient do
        ShowMessage('Impossible de charger les données !');
    end;
  finally
    // Libére la mémoire (obligatoire aprés un .Create).
    LClient.Free;
  end;
end;

procedure TfrmPrincipale.ComboBox1Change(Sender: TObject);
var
  LContenu: string;
  LFichier: string;
  LJson: TJSONData;
  LItem: TJSONData; // TJSONEnum;
  i: integer;
begin
  // On sort si aucune ligne est sélectionnée.
  if ComboBox1.ItemIndex = -1 then
    exit;

  // Défini l'URL des données a télécharger en supprimer les accents de la liste reçu.
  LFichier := LowerCase(RACINE_URL + DOSSIER_API + SupprimerAccents(ComboBox1.Text) + '.json');

  // Efface la liste des élements contenu dans la ValueListEditor
  StringGrid1.Clear;

  // Bloque le rafraichissement de la ValueListEditor.
  StringGrid1.BeginUpdate;

  // Télécharge les données depuis le serveur
  LContenu := GetRequete(LFichier);

  // On extrait les données du JSON, si le serveur a bien renvoyé des éléments
  if LContenu <> '' then
  try
    // Transfer le contenu reçu dans une structure JSON.
    LJson := GetJSON(LContenu);

    StringGrid1.RowCount := {StringGrid1.FixedRows} 1 + LJson.Count;

    // Parcours la liste des éléments JSON pour les afficher dansq la grille
    for i := 0 to LJson.Count - 1 do
    begin
      LItem := LJSon.Items[i];

      StringGrid1.Cells[0, 1 + i] := LItem.FindPath(TJSONObject(LItem).Names[0]).AsString;
      StringGrid1.Cells[1, 1 + i] := LItem.FindPath(TJSONObject(LItem).Names[1]).AsString;
      StringGrid1.Cells[2, 1 + i] := LItem.FindPath(TJSONObject(LItem).Names[2]).AsString;
      StringGrid1.Cells[3, 1 + i] := LItem.FindPath(TJSONObject(LItem).Names[3]).AsString;
      StringGrid1.Cells[4, 1 + i] := LItem.FindPath(TJSONObject(LItem).Names[4]).AsString;
    end;
  finally
    // ATTENTION : Il n'y a pas de Create mais il faut un Free si on veux éviter les pertes de méoires.
    LJson.Free;
  end;

  // Débloque le rafraichissement de la ValueListEditor.
  StringGrid1.EndUpdate;

  // Ajoute un tri alphabêtique sur le noms
  if StringGrid1.RowCount > 1 then
    StringGrid1.SortColRow(true, 1, 1, StringGrid1.RowCount -1);

  // Affiche le nombre d'éléments reçu.
  gbSelection.Caption := IntToStr(StringGrid1.RowCount - 1) + ' ' + ComboBox1.Text;
end;

procedure TfrmPrincipale.FormCreate(Sender: TObject);
begin
  // Création d'un Bitmap pour afficher une partie de la carte.
  FBMP := TBitmap.Create;
  FBMP.PixelFormat := pf24bit;
  FBMP.SetSize(pbPosition.Width, pbPosition.Height);

  // Initialise l'URL a télécharger
  FLien := '';

  // Ratio, pour tenir compte de la différence d'échelle entre les coordonnées dans les listes est celles affichés dans ce programme.
  FS := 21600 / LARGEUR;
end;

procedure TfrmPrincipale.FormDestroy(Sender: TObject);
begin
  // Libéree la mémoire (obligatoire aprés un Create).
  FBMP.Free;
end;

procedure TfrmPrincipale.FormShow(Sender: TObject);
begin
  // Ajuste l'affichage de l'image.
  ImgMonde.Width  := LARGEUR;
  ImgMonde.Height := HAUTEUR;

  // Charger la liste des tébles.
  ChargerListes;

  // Créer la palette de couleurs
  CreerPalette;

  // Charger les données de la carte du monde.
  ChargerMonde;

  // Afficher la carte intégrale.
  AfficherMonde;

  // Affiche la région dans la PaintBox.
  AffichePosition('', -1, -1);

  // Centrer la Scrollbox.
  sbCarte.HorzScrollBar.Position := (LARGEUR - tsMonde.Width) div 2;
  sbCarte.VertScrollBar.Position := (HAUTEUR - tsMonde.Height) div 2;

  hpInformations.SetHtmlFromStr(GetRequete(RACINE_URL + DOSSIER_API));
end;

procedure TfrmPrincipale.hpInformationsHotClick(Sender: TObject);
begin
  if FLien <> '' then
    hpInformations.SetHtmlFromStr(GetRequete(FLien));
end;

procedure TfrmPrincipale.hpInformationsHotURL(Sender: TObject; const URL: String);
begin
  if LeftStr(Url, 9) = DOSSIER_API then
    FLien := RACINE_URL + URL
  else
    FLien := '';
end;

procedure TfrmPrincipale.pbPositionPaint(Sender: TObject);
begin
  // Affiche la Bitmap dans la PaintBox
  pbPosition.Canvas.Draw(0, 0, FBMP);
end;

procedure TfrmPrincipale.pbPositionResize(Sender: TObject);
var
  R: integer;
begin
  // On mémorise la ligne sélectionné avec la souris.
  R := StringGrid1.Row;

  // On recharge la position.
  if R = 0 then
    AffichePosition('', -1, -1)
  else
    AffichePosition(StringGrid1.Cells[1, R], StringGrid1.Cells[2, R].ToInteger, StringGrid1.Cells[3, R].ToInteger);

  // Forcer le rafraichissement de le la PaintBox.
  pbPosition.Invalidate;
end;

procedure TfrmPrincipale.StringGrid1Click(Sender: TObject);
var
  R: integer;
begin
  // On mémorise la ligne sélectionné avec la souris.
  R := StringGrid1.Row;

  // On sort si on a cliquer sur l'entête
  if R = 0 then
    Exit;

  AffichePosition(StringGrid1.Cells[1, R], StringGrid1.Cells[2, R].ToInteger, StringGrid1.Cells[3, R].ToInteger);

  // Forcer le rafraichissement de le la PaintBox.
  pbPosition.Invalidate;
end;

procedure TfrmPrincipale.StringGrid1Resize(Sender: TObject);
begin
  StringGrid1.Columns[1].Width :=StringGrid1.ClientWidth - (StringGrid1.Columns[0].Width + StringGrid1.Columns[2].Width + StringGrid1.Columns[3].Width + StringGrid1.Columns[4].Width);
end;

procedure TfrmPrincipale.AffichePosition(const ANom: string; const AX, AY: Integer);
var
  x, y: Cardinal;
  CX, CY, PX, PY, MX, MY: integer;
  Ligne: PRGBTripleArr;
begin
  // Modifie la taille de la Bitmap si besoin suite au redimensionnement de la fenêtre.
  if (FBMP.Width <>  pbPosition.Width) or (FBMP.Height <> pbPosition.Height) then
    FBMP.SetSize(pbPosition.Width, pbPosition.Height);

  // On éfface la position si l'élément n'en a pas.
  if (AX = -1) and (AY = -1) then
  begin
    // Efface la position
    FBMP.Canvas.Brush.Color := clSkyBlue;
    FBMP.Canvas.Brush.Style := bsSolid;
    FBMP.Canvas.FillRect(0, 0, FBMP.Width, FBMP.Height);
  end
  else
  begin
    // Défini les coordonnées d'affichage de l'élément.
    CX := Trunc(AX / FS);
    CY := Trunc(AY / FS);

    // Calcul la le centre du PaintBox
    MX := pbPosition.Width div 2;
    MY := pbPosition.Height div 2;

    // Défini le point en haut a gauche de la paintBox
    PX := CX - MX;
    PY := CY - MY;

    // On Controle que la position reste dans la zone affichable
    if PY < 0 then
    begin
      PY := 0;
      MY := CY;
    end;

    if (PY + (FBMP.Height - 1) >= HAUTEUR) then
    begin
      PY := HAUTEUR - FBMP.Height;
      MY := CY - PY;
    end;

    FBMP.BeginUpdate;

    // Rempli le bitmap.
    for y := 0 to FBMP.Height - 1 do
    begin
      Ligne := PRGBTripleArr(FBMP.RawImage.GetLineStart(y));

      for x := 0 to FBMP.Width - 1 do
        Ligne^[x] := FCouleurs[FMonde[PY + y, (LARGEUR + PX + x) mod LARGEUR]];
    end;

    FBMP.EndUpdate;

    // Affiche le nom de l'élément
    FBMP.Canvas.Brush.Color := clWhite;
    FBMP.Canvas.Brush.Style := bsClear;
    FBMP.Canvas.Pen.Width   := 2;
    FBMP.Canvas.Pen.Color   := clRed;
    FBMP.Canvas.Ellipse(MX - 5, MY - 5, MX + 5, MY + 5);
  end;
end;

procedure TfrmPrincipale.AfficherMonde;
var
  FMAP: TBitmap;
  x, y: Cardinal;
  Ligne: PRGBTripleArr;
begin
  // Création d'un Bitmap pour afficher le monde dans son intégralité.
  FMAP := TBitmap.Create;
  FMAP.PixelFormat := pf24bit;
  FMAP.SetSize(LARGEUR, HAUTEUR);

  FMAP.BeginUpdate;

  // Rempli le bitmap.
  for y := 0 to HAUTEUR - 1 do
  begin
    Ligne := PRGBTripleArr(FMAP.RawImage.GetLineStart(y));

    for x := 0 to LARGEUR - 1 do
      Ligne^[x] := FCouleurs[FMonde[y, x]];
  end;

  FMAP.EndUpdate;

  // Affiche l'image de la carte
  imgMonde.Picture.Assign(FMAP);

  FMAP.Free;
end;

function TfrmPrincipale.SupprimerAccents(const AValue: string): String;
begin
  Result := AValue;
  Result := StringReplace(Result, 'à', 'a', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'â', 'a', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'é', 'e', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'è', 'e', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'ê', 'e', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'î', 'i', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'ô', 'o', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'ù', 'u', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'û', 'u', [rfReplaceAll, rfIgnoreCase]);
end;

procedure TfrmPrincipale.CreerPalette;
var
  P: Byte;
begin
  // Création de la palette de couleurs
  FCouleurs[0] := ColorToRVB($07162D);   // -30000 m
  P := Degrader(0, 75,  $0F2F60);        // -5000 m
  P := Degrader(P, 81,  $0D4978);        // -4500 m
  P := Degrader(P, 88,  $0A6291);        // -4000 m
  P := Degrader(P, 100, $087CA8);        // -3000 m
  P := Degrader(P, 113, $0695C2);        // -2000 m
  P := Degrader(P, 136, $087999);        // -200 m
  P := Degrader(P, 140, $0391B7);        // -50 m
  FCouleurs[141] := ColorToRVB($0B9AB9); // -10 m
  FCouleurs[142] := ColorToRVB($18ABBD); // -1
  FCouleurs[143] := ColorToRVB($F5E99C); // 0 m (niveau de la mer)
  P := Degrader(143, 146, $E4D995);      // 200 m
  P := Degrader(P,   150, $D4C98C);      // 400 m
  P := Degrader(P,   153, $C3B884);      // 600 m
  P := Degrader(P,   156, $B3A97C);      // 800 m
  P := Degrader(P,   158, $A19874);      // 1000 m
  P := Degrader(P,   163, $91896D);      // 1400 m
  P := Degrader(P,   168, $7F7965);      // 1800 m
  P := Degrader(P,   183, $6E685D);      // 3000 m
  P := Degrader(P,   220, $635D56);      // 5000 m
  P := Degrader(P,   233, $B7B4B0);      // 6000 m
  P := Degrader(P,   245, $DDDDDD);      // 8000 m
  P := Degrader(P,   255, $FFFFFF);      // 9000 m
end;

function TfrmPrincipale.Degrader(const ADepart, AProfondeur: Byte; ACouleur: TColor): Byte;
var
  U, Z: Byte;
  RMoy, VMoy, BMoy: real;
begin
  Result := AProfondeur;

  Z := AProfondeur - ADepart;

  if Z > 0 then
  begin
    FCouleurs[AProfondeur] := ColorToRVB(ACouleur);

    RMoy := (FCouleurs[AProfondeur].R - FCouleurs[ADepart].R) / Z;
    VMoy := (FCouleurs[AProfondeur].V - FCouleurs[ADepart].V) / Z;
    BMoy := (FCouleurs[AProfondeur].B - FCouleurs[ADepart].B) / Z;

    for U := 1 to Z - 1 do
    begin
      FCouleurs[ADepart + U].R := FCouleurs[ADepart].R + round(U * RMoy);
      FCouleurs[ADepart + U].V := FCouleurs[ADepart].V + round(U * VMoy);
      FCouleurs[ADepart + U].B := FCouleurs[ADepart].B + round(U * BMoy);
    end;
  end;
end;

procedure TfrmPrincipale.ChargerListes;
var
  LContenu: string;
  LFichier: string;
  LJson: TJSONData;
  LItem: TJSONEnum;
begin
  // Défini l'URL des données a télécharger
  LFichier := LowerCase(RACINE_URL + DOSSIER_API + 'listes.json');

  // Bloque le rafraichissement de la ComboBox.
  ComboBox1.Items.BeginUpdate;

  // Télécharge les données depuis le serveur
  LContenu:= GetREquete(LFichier);

  // On extrait les données du JSON, si le serveur a bien renvoyé des éléments
  if LContenu <> '' then
  try
    // Transfer le contenu reçu dans une structure JSON.
    LJson := GetJSON(LContenu);

    // Parcours la liste des éléments JSON pour les afficher
    for LItem in LJson do
      ComboBox1.Items.Add(LItem.Value.Items[0].AsString);
  finally
    // ATTENTION : Il n'y a pas de Create mais il faut un Free si on veux éviter les pertes de méoires.
    LJson.Free;
  end;

  // Débloque le rafraichissement de la ComboBox.
  ComboBox1.Items.EndUpdate;

  // Défini le nombre de lignes visible en fonction du nombre reçu d'élements.
  ComboBox1.DropDownCount:= ComBoBox1.Items.Count;
end;

procedure TfrmPrincipale.ChargerMonde;
const
  FichierMonde = 'monde.polaris';
var
  FSR: TFileStream;
  FDS: TDecompressionStream;
begin
  // Véfie si le fichier des données brute est présent a coté du programme.
  if FileExists(FichierMonde) then
  begin
    // Charge et recopie dans le tableau FCarte tout le contenu du fichier.
    FSR := TFileStream.Create(FichierMonde, fmOpenRead);
    try
      FDS := TDecompressionStream.Create(FSR);
      try
        FDS.Read(FMonde, Sizeof(FMonde));
      finally
        FDS.Free;
      end;
    finally
      FSR.Free;
    end;
  end
  else
  begin
    ShowMessage('Le fichier des données de la carte est introuvable !');
  end;
end;

end.

