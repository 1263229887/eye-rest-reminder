package main

import (
	"context"
	"encoding/json"
	"math"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/getlantern/systray"
	"github.com/wailsapp/wails/v2/pkg/runtime"
)

type ReminderSettings struct {
	ShortIntervalMinutes int `json:"shortIntervalMinutes"`
	ShortDurationSeconds int `json:"shortDurationSeconds"`
	LongIntervalMinutes  int `json:"longIntervalMinutes"`
	LongDurationMinutes  int `json:"longDurationMinutes"`
}

func defaultSettings() ReminderSettings {
	return ReminderSettings{ShortIntervalMinutes: 20, ShortDurationSeconds: 20, LongIntervalMinutes: 60, LongDurationMinutes: 5}
}

type settingsStore struct {
	path string
	mu   sync.Mutex
}

func newSettingsStore() *settingsStore {
	d, _ := os.UserConfigDir()
	dir := filepath.Join(d, "EyeRestReminder")
	os.MkdirAll(dir, 0755)
	return &settingsStore{path: filepath.Join(dir, "settings.json")}
}

func (s *settingsStore) load() ReminderSettings {
	s.mu.Lock()
	defer s.mu.Unlock()
	b, err := os.ReadFile(s.path)
	if err != nil { return defaultSettings() }
	var rs ReminderSettings
	if json.Unmarshal(b, &rs) != nil { return defaultSettings() }
	def := defaultSettings()
	if rs.ShortIntervalMinutes == 0 { rs.ShortIntervalMinutes = def.ShortIntervalMinutes }
	if rs.ShortDurationSeconds == 0 { rs.ShortDurationSeconds = def.ShortDurationSeconds }
	if rs.LongIntervalMinutes == 0 { rs.LongIntervalMinutes = def.LongIntervalMinutes }
	if rs.LongDurationMinutes == 0 { rs.LongDurationMinutes = def.LongDurationMinutes }
	return rs
}

func (s *settingsStore) save(rs ReminderSettings) {
	s.mu.Lock()
	defer s.mu.Unlock()
	b, _ := json.MarshalIndent(rs, "", "  ")
	os.WriteFile(s.path, b, 0644)
}

type ReminderKind string
const (
	KindShort ReminderKind = "short"
	KindLong  ReminderKind = "long"
)

type AppState struct {
	Enabled        bool         `json:"enabled"`
	Resting        bool         `json:"resting"`
	ActiveKind     ReminderKind `json:"activeKind"`
	ActiveName     string       `json:"activeName"`
	Remaining      int          `json:"remaining"`
	Progress       float64      `json:"progress"`
	Message        string       `json:"message"`
	ShortRemaining int          `json:"shortRemaining"`
	ShortTotal     int          `json:"shortTotal"`
	LongRemaining  int          `json:"longRemaining"`
	LongTotal      int          `json:"longTotal"`
	NextName       string       `json:"nextName"`
	NextSeconds    int          `json:"nextSeconds"`
}

type scheduler struct {
	store         *settingsStore
	settings      ReminderSettings
	mu            sync.Mutex
	enabled       bool
	elapsed       int
	activeKind    ReminderKind
	remaining     int
	endTime       time.Time
	stopCh        chan struct{}
	onStateChange func(AppState)
}

func newScheduler(store *settingsStore) *scheduler {
	return &scheduler{
		store:    store,
		settings: store.load(),
		enabled:  true,
		stopCh:   make(chan struct{}),
	}
}

func (s *scheduler) start() {
	go func() {
		t := time.NewTicker(1 * time.Second)
		defer t.Stop()
		for {
			select {
			case <-s.stopCh: return
			case <-t.C: s.tick()
			}
		}
	}()
}

func (s *scheduler) stop() { close(s.stopCh) }

func (s *scheduler) tick() {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.enabled { s.emitLocked(); return }
	if s.activeKind != "" {
		rem := s.endTime.Sub(time.Now())
		if rem <= 0 {
			s.skipLocked()
		} else {
			s.remaining = int(math.Ceil(rem.Seconds()))
		}
	} else {
		s.elapsed++
		longSec := max(1, s.settings.LongIntervalMinutes) * 60
		shortSec := max(1, s.settings.ShortIntervalMinutes) * 60
		if s.elapsed%longSec == 0 {
			s.beginLocked(KindLong, s.settings.LongDurationMinutes*60)
		} else if s.elapsed%shortSec == 0 {
			s.beginLocked(KindShort, s.settings.ShortDurationSeconds)
		}
	}
	s.emitLocked()
}

func (s *scheduler) beginLocked(k ReminderKind, sec int) {
	s.activeKind = k; s.remaining = sec; s.endTime = time.Now().Add(time.Duration(sec) * time.Second)
}
func (s *scheduler) skipLocked() { s.activeKind = ""; s.remaining = 0; s.elapsed = 0 }

func (s *scheduler) buildState() AppState {
	st := AppState{Enabled: s.enabled}
	shortSec := max(1, s.settings.ShortIntervalMinutes) * 60
	longSec := max(1, s.settings.LongIntervalMinutes) * 60
	sRem := shortSec - (s.elapsed % shortSec)
	lRem := longSec - (s.elapsed % longSec)
	st.ShortTotal = s.settings.ShortDurationSeconds
	st.LongTotal = s.settings.LongDurationMinutes * 60
	if s.activeKind != "" {
		st.Resting = true; st.ActiveKind = s.activeKind; st.ActiveName = reminderName(s.activeKind)
		st.Remaining = s.remaining; st.Message = reminderMessage(s.activeKind)
		total := st.ShortTotal; if s.activeKind == KindLong { total = st.LongTotal }
		if total > 0 { st.Progress = 1.0 - float64(s.remaining)/float64(total) }
		if s.activeKind == KindShort { st.LongRemaining = lRem; st.ShortRemaining = s.remaining } else { st.ShortRemaining = sRem; st.LongRemaining = s.remaining }
	} else {
		st.ShortRemaining = sRem; st.LongRemaining = lRem
		if lRem <= sRem { st.NextName = reminderName(KindLong); st.NextSeconds = lRem } else { st.NextName = reminderName(KindShort); st.NextSeconds = sRem }
	}
	return st
}

func (s *scheduler) emitLocked() { if s.onStateChange != nil { s.onStateChange(s.buildState()) } }
func (s *scheduler) getState() AppState { s.mu.Lock(); defer s.mu.Unlock(); return s.buildState() }
func (s *scheduler) setEnabled(v bool) { s.mu.Lock(); defer s.mu.Unlock(); s.enabled = v; if !v { s.skipLocked() }; s.emitLocked() }
func (s *scheduler) skip() { s.mu.Lock(); defer s.mu.Unlock(); s.skipLocked(); s.emitLocked() }
func (s *scheduler) reset_() { s.mu.Lock(); defer s.mu.Unlock(); s.skipLocked(); s.emitLocked() }
func (s *scheduler) updateSettings(rs ReminderSettings) {
	s.mu.Lock(); s.settings = rs; s.store.save(rs); s.mu.Unlock()
	if s.onStateChange != nil { s.onStateChange(s.getState()) }
}

type App struct {
	ctx   context.Context
	sched *scheduler
	store *settingsStore
}

func NewApp() *App { return &App{} }

func (a *App) startup(ctx context.Context) {
	a.ctx = ctx
	a.store = newSettingsStore()
	a.sched = newScheduler(a.store)

	a.sched.onStateChange = func(st AppState) {
		runtime.EventsEmit(ctx, "state", st)
		// 休息开始→全屏置顶，休息结束→恢复
		if st.Resting {
			runtime.WindowFullscreen(ctx)
			runtime.WindowSetAlwaysOnTop(ctx, true)
		} else {
			runtime.WindowUnfullscreen(ctx)
			runtime.WindowSetAlwaysOnTop(ctx, false)
		}
	}

	a.sched.start()

	showMainWindowFn = func() { runtime.WindowShow(a.ctx); runtime.WindowCenter(a.ctx) }
	toggleEnabledFn = func() {
		st := a.sched.getState(); a.sched.setEnabled(!st.Enabled)
		if !st.Enabled { systray.SetTooltip("护眼提醒（已暂停）") } else { systray.SetTooltip("护眼提醒") }
	}
	quitAppFn = func() { a.sched.stop(); systray.Quit(); runtime.Quit(a.ctx) }
}

func (a *App) shutdown(ctx context.Context) { a.sched.stop() }

func (a *App) GetState() AppState { return a.sched.getState() }
func (a *App) SetEnabled(v bool) { a.sched.setEnabled(v) }
func (a *App) Skip() { a.sched.skip() }
func (a *App) Reset() { a.sched.reset_() }
func (a *App) GetSettings() ReminderSettings { a.sched.mu.Lock(); defer a.sched.mu.Unlock(); return a.sched.settings }
func (a *App) UpdateSettings(rs ReminderSettings) { a.sched.updateSettings(rs) }
func (a *App) ShowMainWindow() { runtime.WindowShow(a.ctx); runtime.WindowCenter(a.ctx); runtime.WindowUnfullscreen(a.ctx); runtime.WindowSetAlwaysOnTop(a.ctx, false) }
func (a *App) HideToTray() { runtime.WindowHide(a.ctx) }
func (a *App) Quit() { a.sched.stop(); systray.Quit(); runtime.Quit(a.ctx) }

func reminderName(k ReminderKind) string { if k == KindShort { return "小休息" }; return "大休息" }
func reminderMessage(k ReminderKind) string {
	if k == KindShort { return "看向约 6 米以外，让眼睛自然放松。" }
	return "离开屏幕走一走，舒展肩颈和腰背。"
}
func max(a, b int) int { if a > b { return a }; return b }
