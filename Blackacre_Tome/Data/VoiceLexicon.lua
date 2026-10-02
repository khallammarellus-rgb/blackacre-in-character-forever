-- In Character Forever: Journal - Voice Lexicon

Blackacre = Blackacre or {}

Blackacre.VoiceAccentOrder = {
    "auto", "none",
    "scottish", "blunt", "proper_english", "colonial", "native_american",
    "caribbean", "african", "californian", "american",
    "london_old", "london_modern", "nordic_old", "nordic_modern", "measured", "cape",
}

Blackacre.VoiceLanguageOrder = {
    "auto", "none",
    "common", "orcish", "dwarven", "darnassian", "thalassian",
    "taurahe", "zandali", "gutterspeak", "draenei", "goblin", "pandaren", "vulpera",
}

Blackacre.VoiceAccents = {
    scottish = {
        label = "Scottish",
        phrases = {
            { "I am", "I be" },
            { "cannot", "canna" },
            { "will not", "willna" },
            { "do not", "dinna" },
            { "don't", "dinna" },
            { "isn't", "isnae" },
            { "to the", "tae the" },
        },
        words = {
            { "you", "ye" },
            { "your", "yer" },
            { "you're", "ye're" },
            { "my", "ma" },
            { "for", "fer" },
            { "about", "aboot" },
            { "yes", "aye" },
        },
        suffixes = { { "ing", "in'" } },
    },
    blunt = {
        label = "Blunt",
        phrases = {
            { "I am", "I'm" },
            { "do not", "don't" },
            { "cannot", "can't" },
        },
        words = {
            { "and", "an'" },
            { "them", "'em" },
        },
        suffixes = { { "ing", "in'" } },
    },
    proper_english = {
        label = "Proper English",
        phrases = {
            { "I'm", "I am" },
            { "don't", "do not" },
            { "can't", "cannot" },
            { "won't", "will not" },
            { "going to", "going to" },
            { "gonna", "going to" },
            { "wanna", "wish to" },
        },
        words = {
            { "yeah", "yes" },
            { "yep", "yes" },
            { "ok", "very well" },
            { "okay", "very well" },
        },
        suffixes = {},
    },
    colonial = {
        label = "Colonial (American / Canadian)",
        phrases = {
            { "I'm", "I am" },
            { "don't", "do not" },
            { "can't", "cannot" },
            { "won't", "shall not" },
            { "gonna", "going to" },
            { "wanna", "wish to" },
            { "I will", "I shall" },
        },
        words = {
            { "yeah", "yes" },
        },
        suffixes = {},
    },
    native_american = {
        label = "Native American",
        phrases = {
            { "I'm", "I am" },
            { "don't", "do not" },
            { "can't", "cannot" },
            { "won't", "will not" },
            { "gonna", "going to" },
            { "wanna", "want to" },
            { "it's", "it is" },
        },
        words = {
            { "yeah", "yes" },
            { "ok", "yes" },
            { "okay", "yes" },
        },
        suffixes = {},
    },
    caribbean = {
        label = "Caribbean",
        phrases = {},
        words = {
            { "the", "de" },
            { "this", "dis" },
            { "that", "dat" },
            { "they", "dey" },
            { "them", "dem" },
            { "there", "dere" },
            { "these", "dese" },
            { "those", "dose" },
            { "thing", "ting" },
            { "things", "tings" },
            { "with", "wit" },
            { "you", "ya" },
            { "your", "ya" },
        },
        suffixes = { { "ing", "in'" } },
    },
    african = {
        label = "African",
        phrases = {
            { "I'm", "I am" },
            { "don't", "do not" },
            { "gonna", "going to" },
            { "wanna", "want to" },
        },
        words = {
            { "yeah", "yes" },
        },
        suffixes = {},
    },
    californian = {
        label = "Californian",
        phrases = {
            { "I am", "I'm" },
            { "going to", "gonna" },
            { "want to", "wanna" },
            { "kind of", "kinda" },
        },
        words = {
            { "yes", "yeah" },
        },
        suffixes = {},
    },
    american = {
        label = "American (enunciated)",
        phrases = {
            { "gonna", "going to" },
            { "wanna", "want to" },
            { "kinda", "kind of" },
            { "I'm", "I am" },
            { "don't", "do not" },
        },
        words = {
            { "yeah", "yes" },
            { "yep", "yes" },
        },
        suffixes = {},
    },
    london_old = {
        label = "London (old)",
        phrases = {
            { "I am", "I'm" },
        },
        words = {
            { "my", "me" },
            { "hello", "'ello" },
            { "have", "'ave" },
            { "here", "'ere" },
            { "him", "'im" },
            { "her", "'er" },
            { "thing", "fing" },
            { "think", "fink" },
            { "with", "wiv" },
        },
        suffixes = { { "ing", "in'" } },
    },
    london_modern = {
        label = "London (modern)",
        phrases = {
            { "I am", "I'm" },
            { "going to", "gonna" },
        },
        words = {
            { "yes", "yeah" },
        },
        suffixes = { { "ing", "in'" } },
    },
    measured = {
        label = "Measured",
        phrases = {
            { "I'm", "I am" },
            { "don't", "do not" },
            { "can't", "cannot" },
            { "won't", "will not" },
            { "it's", "it is" },
            { "gonna", "going to" },
        },
        words = {
            { "yeah", "yes" },
        },
        suffixes = {},
    },
    nordic_old = {
        label = "Nordic (old)",
        phrases = {
            { "I'm", "I am" },
            { "don't", "do not" },
            { "can't", "cannot" },
            { "won't", "will not" },
            { "gonna", "going to" },
        },
        words = {
            { "think", "tink" },
            { "with", "vit" },
            { "what", "vat" },
            { "thing", "ting" },
            { "things", "tings" },
            { "yes", "yah" },
            { "yeah", "yah" },
        },
        suffixes = {},
    },
    nordic_modern = {
        label = "Nordic (modern)",
        phrases = {
            { "I am", "I'm" },
            { "going to", "gonna" },
        },
        words = {
            { "think", "tink" },
            { "yes", "yah" },
            { "yeah", "yah" },
        },
        suffixes = {},
    },
    cape = {
        label = "Cape",
        phrases = {},
        words = {
            { "think", "tink" },
            { "this", "dis" },
            { "that", "dat" },
            { "with", "wit" },
        },
        suffixes = {},
    },
}

-- Official primer only. Never yes/no/you/the/I/and.
Blackacre.VoiceLanguages = {
    common = { label = "Common" },
    dwarven = { label = "Dwarven" },
    gutterspeak = { label = "Gutterspeak" },
    goblin = { label = "Goblin" },
    vulpera = { label = "Vulpera" },
    orcish = {
        label = "Orcish",
        hello = "Lok-tar",
        goodbye = "Lok-tar ogar",
        agreement = "Zug-zug",
        phrases = {
            { "duel of honor", "mak'gora" },
        },
    },
    darnassian = {
        label = "Darnassian",
        hello = "Elune-adore",
        goodbye = "Ande'thoras-ethil",
        phrases = {
            { "honored teacher", "Shan'do" },
            { "honored student", "Thero'shan" },
        },
    },
    thalassian = {
        label = "Thalassian",
        hello = "Bal'a dash",
        goodbye = "Shorel'aran",
        phrases = {
            { "safe travels", "Al diel shala" },
            { "by the light of the sun", "Anar'alah belore" },
        },
    },
    taurahe = {
        label = "Taur-ahe",
        hello = "Ish-ne-alo por-ah",
        goodbye = "Theia-shoush ahmen",
        phrases = {
            { "tauren", "shu'halo" },
            { "the sun", "An'she" },
            { "the moon", "Mu'sha" },
        },
    },
    zandali = {
        label = "Zandali",
        phrases = {},
    },
    draenei = {
        label = "Draenei",
        phrases = {
            { "good fortune", "Archenon poros" },
        },
    },
    pandaren = {
        label = "Pandaren",
    },
}
