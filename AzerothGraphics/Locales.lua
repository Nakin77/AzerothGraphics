local _, ns = ...

-- English is the reference: it is used for every client language without a
-- translation, and for any text a translation leaves out.
local L = {
    -- Sections and settings
    HEADER_GROUND = "Grass and plants",
    GRASS_DENSITY = "Grass density",
    GRASS_DENSITY_DESC = "How much grass, flowers and small details cover the ground. Higher = fuller ground, but harder on your computer.",
    GRASS_DISTANCE = "Grass distance",
    GRASS_DISTANCE_DESC = "How far around you the grass is shown. Higher = visible farther away.",
    GRASS_FADE = "Grass fade-in",
    GRASS_FADE_DESC = "Distance over which grass appears gradually instead of popping in. Higher = smoother.",

    HEADER_VIEW = "View distance",
    TERRAIN_DETAIL = "Terrain detail",
    TERRAIN_DETAIL_DESC = "How far the ground (hills, mountains) keeps its full detail. Higher = sharper landscape in the distance.",
    OBJECT_DISTANCE = "Object distance",
    OBJECT_DISTANCE_DESC = "How far scenery (trees, rocks, buildings) stays visible, as a percentage. Higher = visible farther away.",
    SMALL_OBJECTS = "Small distant objects",
    SMALL_OBJECTS_DESC = "Far away, objects smaller than this size are hidden. Lower = more small objects visible in the distance.",

    HEADER_IMAGE = "Image and effects",
    SHARPEN = "Always sharpen",
    SHARPEN_DESC = "Makes the image sharper, even when render scale is at 100%. Normally the game only does this below 100%.",
    WATER_REFLECTIONS = "Water reflections",
    WATER_REFLECTIONS_DESC = "Quality of reflections on water: 0 = lowest, 3 = highest.",
    WEATHER = "Weather",
    WEATHER_DESC = "Strength of rain, snow and other weather effects: 0 = none, 3 = maximum.",
    DEATH_EFFECT = "Grey screen when dead",
    DEATH_EFFECT_DESC = "Turns the screen grey while your character is dead.",

    -- Tabs ("where" completes the sentences below that contain %s)
    TAB_GLOBAL = "Global",
    TAB_PARTY = "Dungeons",
    TAB_RAID = "Raids",
    TAB_PVP = "Battlegrounds",
    WHERE_PARTY = "in dungeons",
    WHERE_RAID = "in raids",
    WHERE_PVP = "in battlegrounds",

    -- Line under the tabs
    GLOBAL_NOTE = "Settings used everywhere, except where another tab is turned on.",
    USE_HERE = "Use these settings %s",
    ENABLE_ON = "Checked: %s, these settings replace the Global tab.",
    ENABLE_OFF = "Unchecked: the Global tab also applies %s.",
    ENABLE_KEEP = "Any setting you don't change here stays the same as in the Global tab.",
    IN_USE = "Applied right now: %s",

    -- Setting rows
    DEFAULT_VALUE = "Default: %s",
    UNAVAILABLE = "Not available in this version of the game",
    SAME_AS_GLOBAL = "same as Global",
    CHANGED_HERE = "changed here",
    BUTTON_DEFAULT = "Default",
    BUTTON_DEFAULT_TIP = "Restores the game's default value (%s).",
    BUTTON_GLOBAL = "Use Global",
    BUTTON_GLOBAL_TIP = "Undoes the change made here: this setting goes back to matching the Global tab.",
    RESET_ALL = "Reset all to defaults",
    RESET_ALL_GLOBAL = "Reset all to Global",
    MAX_ALL = "Set all to maximum",
    MAX_ALL_TIP = "Moves every slider to the most detailed setting. Checkboxes are left unchanged. May lower your frame rate.",

    -- Setting tooltips
    TIP_DEFAULT = "Default",
    TIP_RANGE = "Slider range",
    RANGE = "%d to %d",
    TIP_CVAR = "Technical name",
    TIP_TYPE = "You can also type a value in the box, even outside this range.",

    -- Window, options panel and chat
    SUBTITLE = "Changes apply immediately and are kept between sessions.",
    PANEL_HINT = "Type /agfx to open these settings in a movable window.",
    RESET_DONE = "The Global tab settings have been reset to defaults.",
}

local TRANSLATIONS = {}

TRANSLATIONS.frFR = {
    HEADER_GROUND = "Herbe et végétation",
    GRASS_DENSITY = "Densité de l'herbe",
    GRASS_DENSITY_DESC = "Quantité d'herbe, de fleurs et de petits détails au sol. Plus haut = sol plus fourni, mais plus exigeant pour l'ordinateur.",
    GRASS_DISTANCE = "Distance de l'herbe",
    GRASS_DISTANCE_DESC = "Jusqu'à quelle distance l'herbe est affichée autour de vous. Plus haut = visible plus loin.",
    GRASS_FADE = "Fondu de l'herbe",
    GRASS_FADE_DESC = "Distance sur laquelle l'herbe apparaît progressivement au lieu de surgir d'un coup. Plus haut = apparition plus douce.",

    HEADER_VIEW = "Distance d'affichage",
    TERRAIN_DETAIL = "Détail du relief",
    TERRAIN_DETAIL_DESC = "Jusqu'à quelle distance le sol (collines, montagnes) garde tous ses détails. Plus haut = paysage plus précis au loin.",
    OBJECT_DISTANCE = "Distance des objets",
    OBJECT_DISTANCE_DESC = "Jusqu'à quelle distance les éléments du décor (arbres, rochers, bâtiments) restent visibles, en pourcentage. Plus haut = visibles plus loin.",
    SMALL_OBJECTS = "Petits objets lointains",
    SMALL_OBJECTS_DESC = "Au loin, les objets plus petits que cette taille sont cachés. Plus bas = plus de petits objets visibles au loin.",

    HEADER_IMAGE = "Image et effets",
    SHARPEN = "Netteté toujours active",
    SHARPEN_DESC = "Rend l'image plus nette, même quand l'échelle de rendu est à 100 %. Normalement, le jeu ne le fait qu'en dessous de 100 %.",
    WATER_REFLECTIONS = "Reflets sur l'eau",
    WATER_REFLECTIONS_DESC = "Qualité des reflets sur l'eau : 0 = la plus basse, 3 = la plus haute.",
    WEATHER = "Météo",
    WEATHER_DESC = "Intensité de la pluie, de la neige et des autres effets météo : 0 = aucun effet, 3 = maximum.",
    DEATH_EFFECT = "Écran gris à la mort",
    DEATH_EFFECT_DESC = "Affiche l'écran en gris tant que votre personnage est mort.",

    TAB_GLOBAL = "Global",
    TAB_PARTY = "Donjons",
    TAB_RAID = "Raids",
    TAB_PVP = "Champs de bataille",
    WHERE_PARTY = "en donjon",
    WHERE_RAID = "en raid",
    WHERE_PVP = "en champ de bataille",

    GLOBAL_NOTE = "Réglages utilisés partout, sauf là où un autre onglet est activé.",
    USE_HERE = "Utiliser ces réglages %s",
    ENABLE_ON = "Coché : %s, ces réglages remplacent ceux de l'onglet Global.",
    ENABLE_OFF = "Décoché : l'onglet Global s'applique aussi %s.",
    ENABLE_KEEP = "Tout réglage que vous ne changez pas ici reste identique à l'onglet Global.",
    IN_USE = "Appliqué en ce moment : %s",

    DEFAULT_VALUE = "Par défaut : %s",
    UNAVAILABLE = "Non disponible dans cette version du jeu",
    SAME_AS_GLOBAL = "comme Global",
    CHANGED_HERE = "modifié ici",
    BUTTON_DEFAULT = "Par défaut",
    BUTTON_DEFAULT_TIP = "Remet la valeur par défaut du jeu (%s).",
    BUTTON_GLOBAL = "Comme Global",
    BUTTON_GLOBAL_TIP = "Annule le changement fait ici : ce réglage redevient identique à l'onglet Global.",
    RESET_ALL = "Tout remettre par défaut",
    RESET_ALL_GLOBAL = "Tout remettre comme Global",
    MAX_ALL = "Tout mettre au maximum",
    MAX_ALL_TIP = "Pousse chaque curseur vers l'affichage le plus détaillé. Les cases à cocher ne changent pas. Peut faire baisser les images par seconde.",

    TIP_DEFAULT = "Par défaut",
    TIP_RANGE = "Plage du curseur",
    RANGE = "%d à %d",
    TIP_CVAR = "Nom technique",
    TIP_TYPE = "Vous pouvez aussi taper une valeur dans la case, même hors de cette plage.",

    SUBTITLE = "Les changements s'appliquent immédiatement et sont conservés d'une session à l'autre.",
    PANEL_HINT = "Tapez /agfx pour ouvrir ces réglages dans une fenêtre déplaçable.",
    RESET_DONE = "Les réglages de l'onglet Global ont été remis par défaut.",
}

TRANSLATIONS.esES = {
    HEADER_GROUND = "Hierba y vegetación",
    GRASS_DENSITY = "Densidad de la hierba",
    GRASS_DENSITY_DESC = "Cantidad de hierba, flores y pequeños detalles en el suelo. Más alto = suelo más poblado, pero más exigente para tu equipo.",
    GRASS_DISTANCE = "Distancia de la hierba",
    GRASS_DISTANCE_DESC = "Hasta qué distancia se muestra la hierba a tu alrededor. Más alto = visible más lejos.",
    GRASS_FADE = "Transición de la hierba",
    GRASS_FADE_DESC = "Distancia en la que la hierba aparece poco a poco en lugar de surgir de golpe. Más alto = más suave.",

    HEADER_VIEW = "Distancia de visión",
    TERRAIN_DETAIL = "Detalle del terreno",
    TERRAIN_DETAIL_DESC = "Hasta qué distancia el terreno (colinas, montañas) conserva todo su detalle. Más alto = paisaje más nítido a lo lejos.",
    OBJECT_DISTANCE = "Distancia de objetos",
    OBJECT_DISTANCE_DESC = "Hasta qué distancia los elementos del escenario (árboles, rocas, edificios) siguen visibles, en porcentaje. Más alto = visibles más lejos.",
    SMALL_OBJECTS = "Objetos pequeños lejanos",
    SMALL_OBJECTS_DESC = "A lo lejos, los objetos más pequeños que este tamaño se ocultan. Más bajo = más objetos pequeños visibles a lo lejos.",

    HEADER_IMAGE = "Imagen y efectos",
    SHARPEN = "Nitidez siempre activa",
    SHARPEN_DESC = "Hace la imagen más nítida, incluso con la escala de renderizado al 100 %. Normalmente el juego solo lo hace por debajo del 100 %.",
    WATER_REFLECTIONS = "Reflejos en el agua",
    WATER_REFLECTIONS_DESC = "Calidad de los reflejos en el agua: 0 = la más baja, 3 = la más alta.",
    WEATHER = "Clima",
    WEATHER_DESC = "Intensidad de la lluvia, la nieve y otros efectos del clima: 0 = ninguno, 3 = máximo.",
    DEATH_EFFECT = "Pantalla gris al morir",
    DEATH_EFFECT_DESC = "Pone la pantalla en gris mientras tu personaje está muerto.",

    TAB_GLOBAL = "Global",
    TAB_PARTY = "Mazmorras",
    TAB_RAID = "Bandas",
    TAB_PVP = "Campos de batalla",
    WHERE_PARTY = "en mazmorras",
    WHERE_RAID = "en bandas",
    WHERE_PVP = "en campos de batalla",

    GLOBAL_NOTE = "Ajustes usados en todas partes, salvo donde otra pestaña esté activada.",
    USE_HERE = "Usar estos ajustes %s",
    ENABLE_ON = "Marcada: %s, estos ajustes sustituyen a los de la pestaña Global.",
    ENABLE_OFF = "Desmarcada: la pestaña Global se aplica también %s.",
    ENABLE_KEEP = "Cualquier ajuste que no cambies aquí se mantiene igual que en la pestaña Global.",
    IN_USE = "Aplicado ahora: %s",

    DEFAULT_VALUE = "Por defecto: %s",
    UNAVAILABLE = "No disponible en esta versión del juego",
    SAME_AS_GLOBAL = "igual que Global",
    CHANGED_HERE = "cambiado aquí",
    BUTTON_DEFAULT = "Por defecto",
    BUTTON_DEFAULT_TIP = "Restablece el valor por defecto del juego (%s).",
    BUTTON_GLOBAL = "Como Global",
    BUTTON_GLOBAL_TIP = "Deshace el cambio hecho aquí: este ajuste vuelve a ser igual que en la pestaña Global.",
    RESET_ALL = "Restablecer todo",
    RESET_ALL_GLOBAL = "Volver todo a Global",
    MAX_ALL = "Todo al máximo",
    MAX_ALL_TIP = "Lleva cada control al ajuste más detallado. Las casillas no cambian. Puede bajar los fotogramas por segundo.",

    TIP_DEFAULT = "Por defecto",
    TIP_RANGE = "Rango del control",
    RANGE = "%d a %d",
    TIP_CVAR = "Nombre técnico",
    TIP_TYPE = "También puedes escribir un valor en la casilla, incluso fuera de este rango.",

    SUBTITLE = "Los cambios se aplican al instante y se conservan entre sesiones.",
    PANEL_HINT = "Escribe /agfx para abrir estos ajustes en una ventana que se puede mover.",
    RESET_DONE = "Los ajustes de la pestaña Global se han restablecido.",
}
TRANSLATIONS.esMX = TRANSLATIONS.esES

local translation = TRANSLATIONS[GetLocale()]
if translation then
    for key, text in pairs(translation) do L[key] = text end
end

ns.L = L
