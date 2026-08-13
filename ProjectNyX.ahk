#Requires AutoHotkey v2.0
#SingleInstance Force

; ==========================================
; PROJECT NYX V1.1.2 - DEEP LOG ENGINE FIX
; ==========================================
global CURRENT_VER := "Project NyX V1.1.2 Fix"
global FOOTER_TEXT := CURRENT_VER
global LIGHTNING_ICON_URL := "https://cdn-icons-png.flaticon.com/512/1163/1163657.png"
global IniFile := "nyx_config.ini"
global IsRunning := false
global IsPaused := false
global StartTick := 0
global GuiVisible := true
global IsPopping := false

global LogLastPos := 0
global LogActiveBiome := ""
global LogCurrentFile := ""

global InventoryToggleState := 0
global PoppedBiomesTracker := Map()

global StepCoords := Map(
    1, {x: 500, y: 400},
    2, {x: 500, y: 450},
    3, {x: 500, y: 500},
    4, {x: 500, y: 520},
    5, {x: 500, y: 550}
)

global BiomeData := Map(
    "NORMAL",      {color: "00FFCC", image: "https://static.wikia.nocookie.net/sol-rng/images/c/c9/Daytime_img.png"},
    "WINDY",       {color: "38BDF8", image: "https://static.wikia.nocookie.net/sol-rng/images/c/c9/Daytime_img.png"},
    "RAINY",       {color: "10B981", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ4jrbtgFLDivta_Vdw-P1x0Uyk1B16IRRbmI2EHF3Jaw&s=10"},
    "SNOWY",       {color: "FFFFFF", image: "https://static0.thegamerimages.com/wordpress/wp-content/uploads/wm/2025/02/winter-forest-in-sol-s-rng-1.jpg"},
    "SANDSTORM",   {color: "F59E0B", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQnOwtPaYGYOZ-pa7NenFu1VFyATtxwoPNWbALTjlf8DDVeyd7PrzdEIGLX&s=10"},
    "BLAZING SUN", {color: "FFBB00", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQnOwtPaYGYOZ-pa7NenFu1VFyATtxwoPNWbALTjlf8DDVeyd7PrzdEIGLX&s=10"},
    "CYBERSPACE",  {color: "00FFFF", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQSXjCDnj21Cy1vUKeaAv2XZvcrP-gkItL_wWGveraQng&s=10"},
    "HELL",        {color: "FF3300", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSfZ_ojtPs4DOuF6XOL5B4h-d64TZ43-p8ERWfVMX7NJVmBjKNzxE6zU1k&s=10"},
    "HEAVEN",      {color: "FFFF55", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQzAe-xAmt7PlhmxXfmc3CDx8dmsXaPXgFz2aMp_5nlYA&s"},
    "STARFALL",    {color: "38BDF8", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRCecnufgzGJHYTdQLXLqugYrVumwcSty_brAymPSsDKg&s=10"},
    "CORRUPTION",  {color: "AA00AA", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTj5oSJyewPlF6uYx-0DgMtfR06pfGRDLzn2RfqeBMiL-CR_KdTC8dNhLHN&s=10"},
    "NULL",        {color: "AAAAAA", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS5XeQvNZtLhXzo8x2N-hYpm61TgbcECwxHSWYiQrmW3A&s=10"},
    "GLITCHED",    {color: "FFFF00", image: "https://static.wikia.nocookie.net/sol-rng/images/c/cd/Glitch_Tree.png"},
    "DREAMSPACE",  {color: "FF00FF", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ6CQBEjtFn9V6rWutOgKQ4KfHwaqS05YDXSY9ApTydBA&s=10"},
    "EGGLAND",     {color: "00FFFF", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTwLhCATdaobzpQlVWP1w6Wqns_O7lbO_o1BGeshZZqeg&s=10"},
    "SINGULARITY", {color: "FF8800", image: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTwLhCATdaobzpQlVWP1w6Wqns_O7lbO_o1BGeshZZqeg&s=10"}
)

; Bộ danh sách biến thể từ khóa cho từng Biome
global BiomeAliases := Map(
    "GLITCHED",    ["GLITCHED", "GLITCH"],
    "DREAMSPACE",  ["DREAMSPACE", "DREAM SPACE", "DREAM"],
    "CYBERSPACE",  ["CYBERSPACE", "CYBER SPACE", "CYBER"],
    "SINGULARITY", ["SINGULARITY", "SINGULAR"],
    "BLAZING SUN", ["BLAZING SUN", "BLAZING", "SUNNY"],
    "SANDSTORM",   ["SANDSTORM", "SAND"],
    "STARFALL",    ["STARFALL", "STAR"],
    "CORRUPTION",  ["CORRUPTION", "CORRUPT"],
    "HELL",        ["HELL"],
    "HEAVEN",      ["HEAVEN"],
    "NULL",        ["NULL"],
    "EGGLAND",     ["EGGLAND", "EGG"],
    "RAINY",       ["RAINY", "RAIN"],
    "SNOWY",       ["SNOWY", "SNOW"],
    "WINDY",       ["WINDY", "WIND"],
    "NORMAL",      ["NORMAL", "DAY", "DAYTIME"]
)

global WeatherBiomes := ["NORMAL", "WINDY", "RAINY", "SNOWY", "SANDSTORM", "BLAZING SUN",  "HELL",  "HEAVEN",  "STARFALL",  "CORRUPTION",  "NULL"]
global RareBiomes := [ "CYBERSPACE", "GLITCHED", "DREAMSPACE",  ]
global AllBiomes := ["NORMAL", "WINDY", "RAINY", "SNOWY", "SANDSTORM", "BLAZING SUN", "HELL", "HEAVEN", "STARFALL", "CORRUPTION", "NULL", "CYBERSPACE", "GLITCHED", "DREAMSPACE", "EGGLAND", "SINGULARITY"]

global PotionList := [
    "Lucky Potion",
    "Heavenly Potion",
    "Potion of Bound",
    "Transcendent Potion",
    "Warp Potion",
    "Tidal Shifter Potion",
    "Oblivion Potion"
]

global WebhookURL := IniRead(IniFile, "Settings", "Webhook", "")
global Username := IniRead(IniFile, "Settings", "Username", "Player1")
global PSLink := IniRead(IniFile, "Settings", "PSLink", "https://www.roblox.com/share?code=...")
global InvCooldown := IniRead(IniFile, "Settings", "InvCooldown", 10)

global BiomeCounts := Map()
for b in AllBiomes {
    BiomeCounts[b] := IniRead(IniFile, "Counters", b, 0)
    PoppedBiomesTracker[b] := false
}

global PotionControlsPerBiome := Map()

; ==========================================
; USER INTERFACE SETUP
; ==========================================
myGui := Gui("+Resize", CURRENT_VER)
myGui.BackColor := "1E1E1E"
myGui.SetFont("s9", "Segoe UI")

tabs := myGui.Add("Tab3", "x10 y10 w700 h680", ["⚡ Dashboard", "🎒 Auto Inventory & Pop", "📂 Logs", "⚙️ Settings", "👑 Developer Group"])

; --- TAB 1: DASHBOARD ---
tabs.UseTab(1)
myGui.SetFont("s10 Bold", "Segoe UI")
myGui.Add("Button", "x25 y40 w90 h35 c00FF00", "▶ START (F1)").OnEvent("Click", (*) => StartMacro())
myGui.Add("Button", "x120 y40 w90 h35 cFFFF00", "⏸ PAUSE (F2)").OnEvent("Click", (*) => PauseMacro())
myGui.Add("Button", "x215 y40 w90 h35 cFF0000", "⏹ STOP (F3)").OnEvent("Click", (*) => StopMacro())

global LblStatus := myGui.Add("Text", "x25 y82 w280 +0x800 cFF0000", "STATUS: STOPPED")
global LblTimer := myGui.Add("Text", "x320 y82 w200 +0x800 c00FFFF", "RUNNING: 00:00:00")
global LblCurrentBiome := myGui.Add("Text", "x25 y105 w500 +0x800 cFFFF00", "Current: NONE")

myGui.Add("GroupBox", "x25 y125 w650 h520 c00FFFF", " 📊 Biome Counter Dashboard ")
global LblTotalCount := myGui.Add("Text", "x40 y150 w200 +0x800 c00FF00", "Total Detected: 0")
global LblRareCount := myGui.Add("Text", "x250 y150 w200 +0x800 cFF00FF", "Rare Biomes: 0")
myGui.Add("Button", "x535 y146 w125 h26", "🔄 Reset Counts").OnEvent("Click", ResetCounts)

global BiomeLabels := Map()
yPos := 185
xPos := 35
loop AllBiomes.Length {
    bName := AllBiomes[A_Index]
    bHex := BiomeData.Has(bName) ? BiomeData[bName].color : "FFFFFF"
    
    myGui.Add("GroupBox", "x" xPos " y" yPos " w150 h45 c" bHex, "")
    myGui.SetFont("s8 Bold", "Segoe UI")
    myGui.Add("Text", "x" (xPos + 6) " y" (yPos + 12) " w95 h18 +0x800 c" bHex, bName)
    
    myGui.SetFont("s9 Bold", "Consolas")
    BiomeLabels[bName] := myGui.Add("Text", "x" (xPos + 102) " y" (yPos + 11) " w40 h18 +0x800 cFFFFFF", BiomeCounts[bName])
    
    xPos += 160
    if (Mod(A_Index, 4) == 0) {
        xPos := 35
        yPos += 52
    }
}

; --- TAB 2: AUTO INVENTORY & AUTO POP ---
tabs.UseTab(2)
myGui.SetFont("s9 Bold", "Segoe UI")
myGui.Add("Text", "x25 y38 w650 +0x800 cFFFF00", "🎒 AUTO ITEM SCANNER (BIOME RANDOMIZER / STRANGE CONTROLLER)")

global CbBiomeRand := myGui.Add("CheckBox", "x25 y60 w200 c00FFFF", "🎲 Biome Randomizer")
CbBiomeRand.Value := IniRead(IniFile, "Settings", "CbBiomeRand", 1)
global CbStrangeCtrl := myGui.Add("CheckBox", "x230 y60 w200 cFF00FF", "🕹️ Strange Controller")
CbStrangeCtrl.Value := IniRead(IniFile, "Settings", "CbStrangeCtrl", 0)

myGui.Add("Text", "x450 y60 w100 +0x800 cFFFFFF", "⏱️ CD (s):")
global EdInvCooldown := myGui.Add("Edit", "x520 y56 w50", InvCooldown)
myGui.Add("Button", "x580 y55 w95 h25 c00FF00", "💾 Save All").OnEvent("Click", SaveInvSettings)

myGui.Add("GroupBox", "x25 y90 w650 h195 c00FFCC", " 🧪 CẤU HÌNH THUỐC VÀ SỐ LƯỢNG RIÊNG CHO TỪNG BIOME ")
myGui.SetFont("s9", "Segoe UI")
myGui.Add("Text", "x40 y115 w120 +0x800 cFFFF00", "Chọn Biome:")

global DdlBiomes := myGui.Add("DropDownList", "x160 y112 w180 Choose1", AllBiomes)
DdlBiomes.OnEvent("Change", OnBiomeSelectionChanged)

global BtnResetOneShot := myGui.Add("Button", "x355 y112 w135 h26 cFF00FF", "🔄 Reset One-Shot")
BtnResetOneShot.OnEvent("Click", ResetOneShotTrackers)

global LblBiomeOneShotStatus := myGui.Add("Text", "x500 y115 w160 +0x800 c00FF00", "Trạng thái: Chưa Pop")

for bName in AllBiomes {
    sectionName := "BiomeConfig_" . bName
    pMap := Map()
    
    yOff := 150
    loop PotionList.Length {
        pName := PotionList[A_Index]
        keySanitized := StrReplace(pName, " ", "")
        
        defaultEnable := 0
        pEnable := Integer(IniRead(IniFile, sectionName, keySanitized "_Enable", defaultEnable))
        pQty := Integer(IniRead(IniFile, sectionName, keySanitized "_Qty", 1))
        
        colX := (A_Index <= 4) ? 40 : 360
        rowY := (A_Index <= 4) ? (yOff + (A_Index - 1) * 25) : (yOff + (A_Index - 5) * 25)
        
        cb := myGui.Add("CheckBox", "x" colX " y" rowY " w190 cFFFFFF Hidden", pName)
        cb.Value := pEnable
        cb.OnEvent("Click", (*) => UpdateStep4State())
        
        lbl := myGui.Add("Text", "x" (colX + 195) " y" (rowY + 2) " w30 +0x800 c00FFFF Hidden", "SL:")
        ed := myGui.Add("Edit", "x" (colX + 225) " y" (rowY - 2) " w55 Number Hidden", pQty)
        
        pMap[pName] := {cb: cb, ed: ed}
    }
    PotionControlsPerBiome[bName] := pMap
}

ShowControlsForBiome("NORMAL")

myGui.SetFont("s9", "Segoe UI")
myGui.Add("GroupBox", "x25 y295 w650 h335 c00FFFF", " 🛠️ Coordinates 5-Step Item/Potion Test ")
global BtnSteps := Map()
global LblXYZs := Map()
stepData := [
    {desc: "1. Section / Slot category"},
    {desc: "2. Search bar"},
    {desc: "3. Top item in inventory"},
    {desc: "4. Quantity field (Cần thiết khi cắn thuốc)"},
    {desc: "5. Use button (Uống/Dùng)"}
]
currY := 318
loop stepData.Length {
    i := A_Index
    d := stepData[i]
    coords := StepCoords[i]
    
    myGui.Add("Text", "x35 y" currY " w410 h20 +0x800 cFFFF00", d.desc)
    btn := myGui.Add("Button", "x450 y" (currY - 2) " w85 h22", "Test Step " i)
    lblXYZ := myGui.Add("Text", "x542 y" (currY + 2) " w125 h20 +0x800 c00FF00", "X: " coords.x ", Y: " coords.y)
    
    btn.OnEvent("Click", BindTestStep(i, btn, lblXYZ))
    BtnSteps[i] := btn
    LblXYZs[i] := lblXYZ
    
    currY += 32
}

myGui.SetFont("s8 Italic", "Segoe UI")
myGui.Add("Text", "x35 y580 w625 h20 +0x800 cFFBB00", "💡 Lưu ý: Dùng Biome Randomizer hay Strange Controller thì KHÔNG cần làm bước này.")

myGui.SetFont("s9", "Segoe UI")
myGui.Add("Button", "x170 y605 w360 h26 c00FFFF", "▶ Test Full Steps (Safe Clipboard Paste)").OnEvent("Click", (*) => RunFullStepsWithCountdown())

; --- TAB 3: LOG MONITOR & DIAGNOSTICS ---
tabs.UseTab(3)
myGui.SetFont("s10 Bold", "Segoe UI")
myGui.Add("Text", "x25 y40 w650 +0x800 c00FFFF", "📂 ROBLOX LOG FILE MONITOR & DIAGNOSTICS")
myGui.SetFont("s9", "Segoe UI")
global LblLogPath := myGui.Add("Text", "x25 y70 w650 h40 +0x800 cFFFF00", "Pointing to log file...")

myGui.Add("Button", "x25 y115 w160 h28 c00FF00", "🔍 Refresh Log Path").OnEvent("Click", RefreshLogPath)
myGui.Add("Button", "x195 y115 w180 h28 cFF00FF", "🐛 Scan Current Log Now").OnEvent("Click", ForceScanLogNow)

global EdLogs := myGui.Add("Edit", "x25 y155 w650 h490 ReadOnly VScroll Background111111 c00FFCC", "")

; --- TAB 4: SETTINGS ---
tabs.UseTab(4)
myGui.SetFont("s10 Bold", "Segoe UI")
myGui.Add("Text", "x25 y40 w650 +0x800 c00FF00", "⚙️ DISCORD WEBHOOK & PROFILE")
myGui.SetFont("s9", "Segoe UI")
myGui.Add("Text", "x25 y80 w140 +0x800 c00FFFF", "Webhook URL:")
global EdWebhook := myGui.Add("Edit", "x175 y76 w500", WebhookURL)
myGui.Add("Text", "x25 y120 w140 +0x800 c00FFFF", "Roblox Username:")
global EdUsername := myGui.Add("Edit", "x175 y116 w250", Username)
myGui.Add("Text", "x25 y160 w140 +0x800 c00FFFF", "Private Server Link:")
global EdPS := myGui.Add("Edit", "x175 y156 w500", PSLink)
myGui.Add("Button", "x175 y210 w140 h32 c00FF00", "💾 Save Settings").OnEvent("Click", SaveMainSettings)
myGui.Add("Button", "x325 y210 w140 h32 cFF00FF", "🧪 Test Webhook").OnEvent("Click", TestWebhookAction)

; --- TAB 5: DEVELOPER GROUP ---
tabs.UseTab(5)
myGui.SetFont("s12 Bold", "Segoe UI")
myGui.Add("Text", "x45 y45 w620 +0x800 cFF00FF", "👑 DEVELOPER GROUP - PROJECT NYX")
myGui.SetFont("s10", "Segoe UI")
myGui.Add("GroupBox", "x45 y80 w620 h540 c00FFFF", " 📌 Author & Development Info ")
myGui.SetFont("s11 Bold", "Segoe UI")
myGui.Add("Text", "x75 y120 w560 +0x800 cFFFF00", "• Display Name: [ N.y.X ]")
myGui.SetFont("s10", "Segoe UI")
myGui.Add("Text", "x75 y155 w560 +0x800 c00FF00", "• Account / Discord: justlingg.3")
myGui.Add("Text", "x75 y190 w560 +0x800 cFFFFFF", "• Role: Main Developer & Project Creator")
myGui.Add("Text", "x75 y225 w560 +0x800 c00FFCC", "• Official Tester: lordchym5129")
myGui.Add("Text", "x75 y260 w560 +0x800 c00FFFF", "• Group Status: Exclusive for Sol's RNG Macro.")
myGui.Add("GroupBox", "x75 y310 w560 h180 cFF00FF", " 💬 Message from Dev ")
myGui.SetFont("s9 Italic", "Segoe UI")
myGui.Add("Text", "x95 y350 w520 +0x800 cFFFF00", "V1.1.2 Engine Upgrade: Deep Roblox Player log scanner fixed!")

myGui.Show("w720 h700")
RefreshLogPath()
UpdateDashboardUI()
UpdateStep4State()

; ==========================================
; HELPER & STATE CONTROL FUNCTIONS
; ==========================================
GetLatestPlayerLogFile() {
    logDir := EnvGet("LOCALAPPDATA") "\Roblox\logs"
    latestFile := ""
    latestTime := 0
    
    Loop Files logDir "\*.log" {
        ; Lọc chính xác file log của Roblox Client, bỏ qua Launcher / Crash
        if (InStr(A_LoopFileName, "Launcher") || InStr(A_LoopFileName, "Crash"))
            continue
            
        if (A_LoopFileTimeModified > latestTime) {
            latestTime := A_LoopFileTimeModified
            latestFile := A_LoopFilePath
        }
    }
    return latestFile
}

HasActivePotionsForCurrentBiome() {
    global DdlBiomes, PotionControlsPerBiome
    currBiome := DdlBiomes.Text
    if !PotionControlsPerBiome.Has(currBiome)
        return false
    pMap := PotionControlsPerBiome[currBiome]
    for pName, ctrls in pMap {
        if (ctrls.cb.Value == 1)
            return true
    }
    return false
}

UpdateStep4State() {
    global BtnSteps, LblXYZs, StepCoords
    if !IsSet(BtnSteps) || !BtnSteps.Has(4)
        return
        
    if HasActivePotionsForCurrentBiome() {
        BtnSteps[4].Enabled := true
        LblXYZs[4].Value := "X: " StepCoords[4].x ", Y: " StepCoords[4].y
        LblXYZs[4].Opt("c00FF00")
    } else {
        BtnSteps[4].Enabled := false
        LblXYZs[4].Value := "(Vô hiệu hóa - Không chọn thuốc)"
        LblXYZs[4].Opt("c888888")
    }
}

ShowControlsForBiome(biomeName) {
    global PotionControlsPerBiome, PoppedBiomesTracker, LblBiomeOneShotStatus
    
    for b, pMap in PotionControlsPerBiome {
        showFlag := (b == biomeName)
        for pName, ctrls in pMap {
            if showFlag {
                ctrls.cb.Visible := true
                ctrls.ed.Visible := true
            } else {
                ctrls.cb.Visible := false
                ctrls.ed.Visible := false
            }
        }
    }
    
    if PoppedBiomesTracker.Has(biomeName) && PoppedBiomesTracker[biomeName] {
        LblBiomeOneShotStatus.Value := "Trạng thái: ĐÃ POP RỒI"
        LblBiomeOneShotStatus.Opt("cFF0000")
    } else {
        LblBiomeOneShotStatus.Value := "Trạng thái: Chưa Pop"
        LblBiomeOneShotStatus.Opt("c00FF00")
    }
    UpdateStep4State()
}

OnBiomeSelectionChanged(ctrl, info) {
    selectedBiome := ctrl.Text
    ShowControlsForBiome(selectedBiome)
}

ResetOneShotTrackers(*) {
    global PoppedBiomesTracker, DdlBiomes, LblBiomeOneShotStatus
    currentBiome := DdlBiomes.Text
    PoppedBiomesTracker[currentBiome] := false
    LblBiomeOneShotStatus.Value := "Trạng thái: Chưa Pop"
    LblBiomeOneShotStatus.Opt("c00FF00")
    LogMsg("[One-Shot] Đã reset trạng thái cho Biome [" currentBiome "]. Sẽ cho phép pop lại nếu xuất hiện.")
}

; ==========================================
; HOTKEYS & RUNNER
; ==========================================
F1::StartMacro()
F2::PauseMacro()
F3::StopMacro()
F4::ToggleGuiVisibility()

ToggleGuiVisibility() {
    global GuiVisible
    GuiVisible := !GuiVisible
    if GuiVisible
        myGui.Show()
    else
        myGui.Hide()
}

StartMacro() {
    global IsRunning, IsPaused, StartTick
    if IsRunning && !IsPaused
        return
        
    if IsPaused {
        IsPaused := false
        LblStatus.Value := "STATUS: RUNNING"
        LblStatus.Opt("cLime")
        LogMsg("▶ Macro RESUMED.")
    } else {
        IsRunning := true
        IsPaused := false
        StartTick := A_TickCount
        
        LblStatus.Value := "STATUS: RUNNING"
        LblStatus.Opt("cLime")
        LogMsg("🚀 Project NyX Macro system STARTED!")
        SendMacroStatusWebhook("started")
        
        ; Khởi tạo và quét Biome ban đầu
        InitLogStateOnStart()
        
        SetTimer(LogMonitorLoop, 800)
        SetTimer(TimerLoop, 1000)
        if (CbBiomeRand.Value || CbStrangeCtrl.Value)
            SetTimer(AutoInventoryLoop, 1000)
    }
}

PauseMacro() {
    global IsRunning, IsPaused
    if IsRunning && !IsPaused {
        IsPaused := true
        LblStatus.Value := "STATUS: PAUSED"
        LblStatus.Opt("cYellow")
        LogMsg("⏸ Macro PAUSED.")
        SetTimer(LogMonitorLoop, 0)
        SetTimer(TimerLoop, 0)
        SetTimer(AutoInventoryLoop, 0)
    } else if IsPaused {
        StartMacro()
    }
}

StopMacro() {
    global IsRunning, IsPaused, IsPopping
    wasRunning := IsRunning
    IsRunning := false
    IsPaused := false
    IsPopping := false
    LblStatus.Value := "STATUS: STOPPED"
    LblStatus.Opt("cRed")
    LogMsg("⏹ Macro STOPPED.")
    if (wasRunning) {
        SendMacroStatusWebhook("stopped")
    }
    SetTimer(LogMonitorLoop, 0)
    SetTimer(TimerLoop, 0)
    SetTimer(AutoInventoryLoop, 0)
}

LogMsg(text) {
    timestamp := FormatTime(, "[HH:mm:ss]")
    EdLogs.Value := EdLogs.Value timestamp " " text "`n"
    PostMessage(0x0115, 7, 0, EdLogs.Hwnd)
}

SaveMainSettings(*) {
    global WebhookURL, Username, PSLink
    WebhookURL := EdWebhook.Value
    Username := EdUsername.Value
    PSLink := EdPS.Value
    
    IniWrite(WebhookURL, IniFile, "Settings", "Webhook")
    IniWrite(Username, IniFile, "Settings", "Username")
    IniWrite(PSLink, IniFile, "Settings", "PSLink")
    LogMsg("[Settings] Configuration saved!")
}

SaveInvSettings(*) {
    global InvCooldown, PotionControlsPerBiome
    InvCooldown := EdInvCooldown.Value
    IniWrite(InvCooldown, IniFile, "Settings", "InvCooldown")
    IniWrite(CbBiomeRand.Value, IniFile, "Settings", "CbBiomeRand")
    IniWrite(CbStrangeCtrl.Value, IniFile, "Settings", "CbStrangeCtrl")
    
    for bName, pMap in PotionControlsPerBiome {
        sectionName := "BiomeConfig_" . bName
        for pName, ctrls in pMap {
            keySanitized := StrReplace(pName, " ", "")
            qVal := Integer(ctrls.ed.Value)
            if (qVal < 1)
                qVal := 1
            ctrls.ed.Value := qVal
            
            IniWrite(ctrls.cb.Value, IniFile, sectionName, keySanitized "_Enable")
            IniWrite(qVal, IniFile, sectionName, keySanitized "_Qty")
        }
    }
    UpdateStep4State()
    LogMsg("[Inventory & Pop] All per-biome potion settings saved!")
}

BindTestStep(stepNum, btnCtrl, lblXYZCtrl) {
    return (*) => RunStepWithCountdown(stepNum, btnCtrl, lblXYZCtrl)
}

RunStepWithCountdown(stepNum, btnCtrl, lblXYZCtrl) {
    global StepCoords
    LogMsg("[Inventory] Step " . stepNum . " countdown 3s...")
    
    Loop 3 {
        remaining := 4 - A_Index
        btnCtrl.Text := "⏳ " . remaining . "s"
        Sleep(1000)
    }
    
    CoordMode("Mouse", "Screen")
    MouseGetPos(&screenX, &screenY)
    
    relX := screenX
    relY := screenY
    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinGetPos(&winX, &winY, , , "ahk_exe RobloxPlayerBeta.exe")
        relX := screenX - winX
        relY := screenY - winY
    }
    
    StepCoords[stepNum] := {x: relX, y: relY}
    lblXYZCtrl.Value := "X: " . relX . ", Y: " . relY
    btnCtrl.Text := "Test Step " . stepNum
    LogMsg("[Inventory] Step " . stepNum . " updated: [X: " . relX . ", Y: " . relY . "]")
}

SmoothMove(targetX, targetY) {
    CoordMode("Mouse", "Window")
    MouseGetPos(&startX, &startY)
    steps := 20
    loop steps {
        if (!IsRunning || IsPaused)
            break
        currX := startX + (targetX - startX) * A_Index / steps
        currY := startY + (targetY - startY) * A_Index / steps
        MouseMove(currX, currY, 0)
        Sleep(12)
    }
}

SafeClipboardPaste(textToPaste) {
    A_Clipboard := ""
    A_Clipboard := textToPaste
    if !ClipWait(1) {
        return false
    }
    SendInput("^a")
    Sleep(80)
    SendInput("^v")
    Sleep(150)
    return true
}

RunFullStepsWithCountdown() {
    if !WinExist("ahk_exe RobloxPlayerBeta.exe") {
        LogMsg("[Inventory Error] Roblox window not found!")
        return
    }
    
    hasPotions := HasActivePotionsForCurrentBiome()
    stepsToRun := hasPotions ? [1, 2, 3, 4, 5] : [1, 2, 3, 5]
    searchKeyword := hasPotions ? "Lucky Potion" : "Biome Randomizer"
    
    for stepIdx in stepsToRun {
        coords := StepCoords[stepIdx]
        SmoothMove(coords.x, coords.y)
        Sleep(350)
        Click("Left")
        Sleep(250)
        
        if (stepIdx == 2) {
            SafeClipboardPaste(searchKeyword)
            Sleep(300)
        } else if (stepIdx == 4 && hasPotions) {
            SafeClipboardPaste("1")
            Sleep(250)
        }
    }
    LogMsg("[Test] Test sequence completed!")
}

AutoInventoryLoop() {
    global StepCoords, InventoryToggleState, InvCooldown, IsPopping
    static lastRunTick := 0
    
    if (IsPopping)
        return
        
    if (!WinExist("ahk_exe RobloxPlayerBeta.exe")) {
        LogMsg("[Failsafe] Roblox window lost! Stopping macro.")
        StopMacro()
        return
    }
    if IsRunning && !IsPaused && (CbBiomeRand.Value || CbStrangeCtrl.Value) {
        currentTick := A_TickCount
        cooldownMs := Integer(InvCooldown) * 1000
        
        if ((currentTick - lastRunTick) < cooldownMs && lastRunTick != 0)
            return
            
        lastRunTick := currentTick
        if (CbBiomeRand.Value && CbStrangeCtrl.Value) {
            searchKeyword := (InventoryToggleState == 0) ? "Biome Randomizer" : "Strange Controller"
            InventoryToggleState := 1 - InventoryToggleState
        } else if (CbStrangeCtrl.Value) {
            searchKeyword := "Strange Controller"
        } else {
            searchKeyword := "Biome Randomizer"
        }
        
        stepsToRun := [1, 2, 3, 5]
        for stepIdx in stepsToRun {
            if (!IsRunning || IsPaused || IsPopping || !WinExist("ahk_exe RobloxPlayerBeta.exe"))
                break
                
            coords := StepCoords[stepIdx]
            SmoothMove(coords.x, coords.y)
            Sleep(350)
            Click("Left")
            Sleep(250)
            
            if (stepIdx == 2) {
                SafeClipboardPaste(searchKeyword)
                Sleep(300)
            }
        }
    }
}

ExecutePerBiomeAutoPop(currentBiome) {
    global IsPopping, StepCoords, PotionControlsPerBiome, PoppedBiomesTracker, DdlBiomes, LblBiomeOneShotStatus
    
    if !PotionControlsPerBiome.Has(currentBiome)
        return
        
    pMap := PotionControlsPerBiome[currentBiome]
    activeQueue := []
    
    for pName, ctrls in pMap {
        if (ctrls.cb.Value == 1) {
            qtyVal := Integer(ctrls.ed.Value)
            activeQueue.Push({name: pName, qty: qtyVal})
        }
    }
    
    if (activeQueue.Length == 0) {
        LogMsg("ℹ️ [Auto Pop] Biome [" currentBiome "] không cấu hình cắn thuốc. Bỏ qua.")
        return
    }
        
    IsPopping := true
    LogMsg("🧪 [Auto Pop] Bắt đầu cắn thuốc cho Biome [" currentBiome "]...")
    
    for item in activeQueue {
        if (!IsRunning || IsPaused || !IsPopping || !WinExist("ahk_exe RobloxPlayerBeta.exe"))
            break
            
        LogMsg("🧪 [Auto Pop] Dùng: " item.name " | Số lượng: " item.qty "...")
        
        loop 5 {
            if (!IsRunning || IsPaused || !WinExist("ahk_exe RobloxPlayerBeta.exe"))
                break
                
            stepIdx := A_Index
            coords := StepCoords[stepIdx]
            
            SmoothMove(coords.x, coords.y)
            Sleep(350)
            Click("Left")
            Sleep(250)
            
            if (stepIdx == 2) {
                SafeClipboardPaste(item.name)
                Sleep(350)
            } else if (stepIdx == 4) {
                SafeClipboardPaste(String(item.qty))
                Sleep(250)
            }
        }
        Sleep(500)
    }
    
    PoppedBiomesTracker[currentBiome] := true
    if (DdlBiomes.Text == currentBiome) {
        LblBiomeOneShotStatus.Value := "Trạng thái: ĐÃ POP RỒI"
        LblBiomeOneShotStatus.Opt("cFF0000")
    }
    
    LogMsg("🛑 [Auto Pop] Đã cắn xong cho Biome [" currentBiome "]. Khóa One-Shot.")
    IsPopping := false
}

RefreshLogPath(*) {
    latestFile := GetLatestPlayerLogFile()
    if latestFile
        LblLogPath.Value := "Log file đang theo dõi:`n" latestFile
    else
        LblLogPath.Value := "⚠️ Không tìm thấy file Log Roblox Player nào!"
}

ForceScanLogNow(*) {
    latestFile := GetLatestPlayerLogFile()
    if !latestFile {
        LogMsg("[Debug Check] KHÔNG TÌM THẤY FILE LOG ROBLOX PLAYER!")
        return
    }
    
    try {
        f := FileOpen(latestFile, "r", "UTF-8")
        if !f {
            LogMsg("[Debug Check] Không mở được file log!")
            return
        }
        
        fileSize := f.Length
        readSize := (fileSize > 150000) ? 150000 : fileSize
        f.Seek(fileSize - readSize, 0)
        text := f.Read()
        f.Close()
        
        foundBiome := DetectBiomeFromText(text)
        LogMsg("----------------------------------------")
        LogMsg("🐛 [FORCE SCAN RESULT]")
        LogMsg("📄 File: " latestFile)
        LogMsg("🎯 Detected Biome: " . (foundBiome != "" ? foundBiome : "NONE/NORMAL"))
        LogMsg("----------------------------------------")
    } catch as err {
        LogMsg("[Debug Error] " err.Message)
    }
}

TestWebhookAction(*) {
    SaveMainSettings()
    if WebhookURL {
        TestWebhookEmbed()
    } else {
        LogMsg("[Webhook Error] Chưa nhập URL Discord Webhook!")
    }
}

TestWebhookEmbed() {
    if !WebhookURL
        return
    
    colorDec := Integer("0x00E5FF")
    formattedUser := Chr(96) . Username . Chr(96)
    timeStr := FormatTime(, "HH:mm:ss - dd/MM/yyyy")
    jsonPayload := '{"embeds": [{"title": "🧪 Project NyX V1.1.2 – Test Webhook OK!", "description": "Kết nối Webhook Discord hoạt động bình thường!", "color": ' . colorDec . ', "fields": [{"name": "👤 Username", "value": ' . JsonEscape(formattedUser) . ', "inline": true}, {"name": "⏰ Time", "value": "' . timeStr . '", "inline": true}], "footer": {"text": "' . CURRENT_VER . '", "icon_url": "' . LIGHTNING_ICON_URL . '"}}]}'
    try {
        wh := ComObject("WinHttp.WinHttpRequest.5.1")
        wh.Open("POST", WebhookURL, false)
        wh.SetRequestHeader("Content-Type", "application/json; charset=UTF-8")
        wh.Send(jsonPayload)
        
        status := wh.Status
        if (status >= 200 && status < 300)
            LogMsg("[Webhook Test] Gửi thông báo thử thành công! (Status: " status ")")
        else
            LogMsg("[Webhook Error] Discord từ chối (Status: " status ")")
    } catch Error as err {
        LogMsg("[Webhook Connection Error] " err.Message)
    }
}

SendWebhookEmbed(biomeName, eventType, startTime := "") {
    if !WebhookURL
        return
    
    bKey := StrUpper(biomeName)
    bData := BiomeData.Has(bKey) ? BiomeData[bKey] : {color: "00FF87", image: ""}
    
    colorHex := bData.color
    colorDec := Integer("0x" colorHex)
    imgUrl := bData.image
    
    timeStr := FormatTime(, "HH:mm:ss - dd/MM/yyyy")
    
    if (eventType == "started") {
        titleText := "⚡ Biome Started - " . bKey
        descJson := '"description": ' . JsonEscape("Join Server: " . PSLink) . ', '
        fieldsJson := '[{"name": "👤 Username", "value": "' . Username . '", "inline": true}, {"name": "⏰ Start Time", "value": "' . timeStr . '", "inline": true}]'
    } else {
        titleText := "🛑 Biome Ended - " . bKey
        descJson := ''
        fieldsJson := '[{"name": "👤 Username", "value": "' . Username . '", "inline": true}, {"name": "⏰ End Time", "value": "' . timeStr . '", "inline": true}, {"name": "⏳ Duration", "value": "' . (startTime ? startTime : "Unknown") . '", "inline": false}]'
    }
    
    jsonPayload := '{"embeds": [{"title": "' . titleText . '", "color": ' . colorDec . ', ' . descJson . '"fields": ' . fieldsJson . ', "thumbnail": {"url": "' . imgUrl . '"}, "footer": {"text": "' . FOOTER_TEXT . '", "icon_url": "' . LIGHTNING_ICON_URL . '"}}]}'
    
    try {
        wh := ComObject("WinHttp.WinHttpRequest.5.1")
        wh.Open("POST", WebhookURL, false)
        wh.SetRequestHeader("Content-Type", "application/json; charset=UTF-8")
        wh.Send(jsonPayload)
        LogMsg("[Webhook] Gửi tin nhắn Discord thành công: Biome [" biomeName "] (" eventType ")")
    } catch Error as err {
        LogMsg("[Webhook Connection Error] " err.Message)
    }
}

SendMacroStatusWebhook(state) {
    if !WebhookURL
        return
    
    colorHex := (state == "started") ? "00FF00" : "FF0000"
    colorDec := Integer("0x" colorHex)
    titleText := (state == "started") ? "🚀 Project NyX - Macro Started" : "⏹ Project NyX - Macro Stopped"
    descText := (state == "started") ? "Macro system đã khởi động thành công!" : "Macro system đã dừng."
    timeStr := FormatTime(, "HH:mm:ss - dd/MM/yyyy")
    
    jsonPayload := '{"embeds": [{"title": "' . titleText . '", "description": "' . descText . '", "color": ' . colorDec . ', "fields": [{"name": "👤 Username", "value": "' . Username . '", "inline": true}, {"name": "⏰ Time", "value": "' . timeStr . '", "inline": true}], "footer": {"text": "' . FOOTER_TEXT . '", "icon_url": "' . LIGHTNING_ICON_URL . '"}}]}'
    
    try {
        wh := ComObject("WinHttp.WinHttpRequest.5.1")
        wh.Open("POST", WebhookURL, false)
        wh.SetRequestHeader("Content-Type", "application/json; charset=UTF-8")
        wh.Send(jsonPayload)
    } catch Error as err {
        LogMsg("[Webhook Error] " err.Message)
    }
}

JsonEscape(str) {
    str := StrReplace(str, "\", "\\")
    str := StrReplace(str, '"', '\"')
    str := StrReplace(str, "`n", "\n")
    str := StrReplace(str, "`r", "\r")
    return '"' . str . '"'
}

TimerLoop() {
    elapsed := Integer((A_TickCount - StartTick) / 1000)
    h := Format("{:02}", Floor(elapsed / 3600))
    m := Format("{:02}", Floor(Mod(elapsed, 3600) / 60))
    s := Format("{:02}", Mod(elapsed, 60))
    LblTimer.Value := "RUNNING: " h ":" m ":" s
}

ResetCounts(*) {
    global BiomeCounts
    for b in AllBiomes {
        BiomeCounts[b] := 0
        IniWrite(0, IniFile, "Counters", b)
    }
    UpdateDashboardUI()
    LogMsg("[Dashboard] Đã reset bộ đếm Biome.")
}

UpdateDashboardUI() {
    total := 0
    rareTot := 0
    for b, count in BiomeCounts {
        total += count
        for rb in RareBiomes {
            if (rb == b)
                rareTot += count
        }
        if BiomeLabels.Has(b)
            BiomeLabels[b].Value := count
    }
    LblTotalCount.Value := "Total Detected: " total
    LblRareCount.Value := "Rare Biomes: " rareTot
}

; ==========================================
; LOG SCANNER ENGINE (ULTRA DEEP SCAN V1.1.2)
; ==========================================
InitLogStateOnStart() {
    global LogLastPos, LogActiveBiome, LogCurrentFile, LblCurrentBiome
    
    latestFile := GetLatestPlayerLogFile()
    if !latestFile {
        LogActiveBiome := "NORMAL"
        LblCurrentBiome.Value := "Current: NORMAL"
        return
    }
    
    LogCurrentFile := latestFile
    
    try {
        f := FileOpen(latestFile, "r", "UTF-8")
        if !f
            return
            
        fileSize := f.Length
        LogLastPos := fileSize
        
        readSize := (fileSize > 150000) ? 150000 : fileSize
        f.Seek(fileSize - readSize, 0)
        text := f.Read()
        f.Close()
        
        foundBiome := DetectBiomeFromText(text)
        if (foundBiome == "")
            foundBiome := "NORMAL"
            
        LogActiveBiome := foundBiome
        LblCurrentBiome.Value := "Current: " . foundBiome
        
        HandleBiomeStarted(foundBiome)
        
    } catch as err {
        LogActiveBiome := "NORMAL"
        LblCurrentBiome.Value := "Current: NORMAL"
    }
}

DetectBiomeFromText(textBlock) {
    global BiomeAliases
    
    lines := StrSplit(textBlock, "`n", "`r")
    
    ; Quét ngược từ dòng mới nhất lên dòng cũ hơn
    loop lines.Length {
        idx := lines.Length - A_Index + 1
        line := lines[idx]
        if (line == "")
            continue
            
        lineUpper := StrUpper(line)
        
        ; Quét tất cả Aliases từ danh sách Biome
        for targetBiome, aliases in BiomeAliases {
            for alias in aliases {
                ; Tìm kiếm từ khóa xuất hiện trong log
                if RegExMatch(lineUpper, "i)\b" . alias . "\b") {
                    return targetBiome
                }
            }
        }
    }
    return ""
}

LogMonitorLoop() {
    global LogLastPos, LogActiveBiome, LogCurrentFile
    static biomeStartTime := 0
    
    latestFile := GetLatestPlayerLogFile()
    if !latestFile
        return
        
    if (LogCurrentFile != latestFile) {
        InitLogStateOnStart()
        return
    }
    
    try {
        f := FileOpen(latestFile, "r", "UTF-8")
        if !f
            return
            
        currLen := f.Length
        
        if (currLen < LogLastPos) {
            LogLastPos := currLen
            f.Close()
            return
        }
        
        if (currLen > LogLastPos) {
            f.Seek(LogLastPos, 0)
            text := f.Read()
            f.Close()
            LogLastPos := currLen
            
            foundBiome := DetectBiomeFromText(text)
            
            if (foundBiome != "" && foundBiome != LogActiveBiome) {
                if (LogActiveBiome != "" && LogActiveBiome != "NONE") {
                    durationSec := Integer((A_TickCount - biomeStartTime) / 1000)
                    durFormatted := Format("{:02}m {:02}s", Floor(durationSec / 60), Mod(durationSec, 60))
                    HandleBiomeEnded(LogActiveBiome, durFormatted)
                }
                LogActiveBiome := foundBiome
                biomeStartTime := A_TickCount
                HandleBiomeStarted(foundBiome)
            }
        } else {
            f.Close()
        }
    } catch as err {
        try f.Close()
    }
}

HandleBiomeStarted(biome) {
    global BiomeCounts, PoppedBiomesTracker
    
    BiomeCounts[biome] := BiomeCounts[biome] + 1
    IniWrite(BiomeCounts[biome], IniFile, "Counters", biome)
    
    LogMsg("⚡ DETECTED: Biome [" . biome . "]!")
    LblCurrentBiome.Value := "Current: " biome
    UpdateDashboardUI()
    
    SendWebhookEmbed(biome, "started")
    
    if PoppedBiomesTracker.Has(biome) && PoppedBiomesTracker[biome] {
        LogMsg("ℹ️ Biome [" biome "] ĐÃ POP TRƯỚC ĐÓ. Bỏ qua (One-Shot Rule).")
        return
    }
    
    if IsRunning && !IsPaused {
        ExecutePerBiomeAutoPop(biome)
    }
}

HandleBiomeEnded(biome, durationStr) {
    global IsPopping
    LogMsg("🛑 Biome [" . biome . "] kết thúc. Thời gian: " . durationStr)
    SendWebhookEmbed(biome, "ended", durationStr)
    LblCurrentBiome.Value := "Current: NONE"
    IsPopping := false
}
