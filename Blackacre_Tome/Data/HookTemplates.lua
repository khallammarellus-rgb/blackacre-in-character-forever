-- In Character Forever: Journal - Page Templates

Blackacre = Blackacre or {}

Blackacre.HookTemplates = {
    QUEST = {
        "It was {yearKC} {month}, and {day} and I just marked another milestone in my personal histories. . .({questName}). {questOffer} {questReward}",
    },
    QUESTLINE = {
        "It was {yearKC} {month}, and {day} in the {dayDescription} and it was {weatherText}. {giverName} just sent me on an errand. . . {questOffer}",
        "I finished {giverName}'s. . .({questReward})",
    },
    META_QUEST = {
        "It was {yearKC} {month}, and {day}",
    },
    META_ACHIEVEMENT = {
        "{yearKC} {month}, and {day} my long journey came to an end after an exhausting tour. . .",
    },
    FOS = {
        "Today I impressed myself well enough by achieving {achievementName} and I feel more esteemed. . .",
    },
    REPUTATION = {
        "{yearKC} {month}, and {day}, my standing with the {factionName} rose. I am earning their trust. . .I must not squander it. . .",
    },
    ACHIEVEMENT = {
        "{yearKC} {month}, and {day}. Huzzah! I made a personal achievement today! {achievementName} {achievementDetail}",
        "My deeds aggregate more and more! {yearKC} {month}, and {day} is the day I made a mark in the annals of history. {achievementName} {achievementDetail}",
    },
    TITLE = {
        "This day on {yearKC} {month} {day} I was bestowed the title of {titleName}. . .",
    },
    WEAPON_SKILL = {
        "It was {yearKC} {month}, and {day}, and my hand knows {skillName} as well as any hand can. There is no more the drills can teach me. . .",
        "It was {yearKC} {month}, and {day}. Years of practice, and today I felt it: I have mastered {skillName}. . .",
    },
    PROFESSION = {
        apprentice = "It was {yearKC} {month}, and {day} and I have completed my apprenticeship in {skillName}.",
        journeyman = "It was {yearKC} {month}, and {day} and I stand as a journeyman of {skillName}.",
        expert = "It was {yearKC} {month}, and {day} and my {skillName} is called expert work.",
        artisan = "It was {yearKC} {month}, and {day} and I have reached artisan in {skillName}.",
    },
    MANUAL = {
        "{manualTitle}. {manualBody}",
    },
    DEATH = {
        "It was {yearKC} {month}, and {day} and I felt the cold grasp me. . .my Rites before me await.",
    },
    AFTERLIFE = {
        "I write this down to remember the solemnity of the Rites of Return I endures to walk the path back and continue the journey this day of {yearKC} {month} {day}",
    },
    PVP = {
        defeat = "{pvpBody}",
        victory = "{pvpBody}",
    },
    DEFAULT = {
        "It is {yearKC} {month} and {day}, and I mark this moment today. . .",
    },
}

-- Level-band flavor fragments for optional templates that use {seasoning}
Blackacre.HookSeasoning = {
    { maxLevel = 20, text = "young and untested" },
    { maxLevel = 40, text = "still early on the path" },
    { maxLevel = 60, text = "seasoned by road and trial" },
    { maxLevel = 80, text = "hard-forged by long campaign" },
    { maxLevel = 999, text = "weathered as old stone" },
}
