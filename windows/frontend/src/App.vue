<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { GetState, SetEnabled, Skip, Reset, GetSettings, UpdateSettings, HideToTray, Quit } from '../wailsjs/go/main/App'
import { EventsOn, EventsOff } from '../wailsjs/runtime/runtime'

const st = ref({ enabled: true, resting: false, activeKind: '', activeName: '', remaining: 0, progress: 0, message: '', shortRemaining: 0, shortTotal: 20, longRemaining: 0, longTotal: 300, nextName: '', nextSeconds: 0 })
const s = ref({ shortIntervalMinutes: 20, shortDurationSeconds: 20, longIntervalMinutes: 60, longDurationMinutes: 5 })
const showSet = ref(false)
const overlay = ref(false)

const fmt = (t) => `${String(Math.floor(t / 60)).padStart(2, '0')}:${String(t % 60).padStart(2, '0')}`

const sPct = computed(() => Math.max(0, Math.min(100, (1 - st.value.shortRemaining / Math.max(st.value.shortTotal, 60)) * 100)))
const lPct = computed(() => Math.max(0, Math.min(100, (1 - st.value.longRemaining / Math.max(st.value.longTotal, 60)) * 100)))
const pPct = computed(() => Math.max(0, Math.min(100, st.value.progress * 100)))

async function load() {
  try { st.value = await GetState(); s.value = await GetSettings() } catch (e) { console.error(e) }
}
async function toggle() { await SetEnabled(!st.value.enabled); await load() }
async function doSkip() { await Skip(); await load() }
async function doReset() { await Reset(); await load() }
async function save(k, v) { s.value[k] = Math.max(1, Math.min(999, Number(v) || 0)); await UpdateSettings(s.value); s.value = await GetSettings() }
function hide() { HideToTray() }
function exit() { Quit() }

// Intercept close → hide to tray
// beforeunload is unreliable with WebView2, so we keep native close
// and ask user to use system tray

onMounted(async () => {
  await load()
  EventsOn('state', (v) => { st.value = v; if (v.resting && !overlay.value) overlay.value = true; else if (!v.resting && overlay.value) overlay.value = false }  )
  EventsOn('show-overlay', () => overlay.value = true)
  EventsOn('hide-overlay', () => overlay.value = false)
})
onUnmounted(() => { EventsOff('state'); EventsOff('show-overlay'); EventsOff('hide-overlay') })
function skipOver() { doSkip() }
</script>

<template>
  <div class="app">
    <!-- === 头部 === -->
    <div class="head">
      <div class="head-left">
        <div class="logo">👁</div>
        <div class="head-title">护眼提醒</div>
      </div>
      <label class="tg"><input type="checkbox" :checked="st.enabled" @change="toggle" /><span class="tg-sl"></span></label>
    </div>

    <!-- === 内容 === -->
    <div class="body">

      <!-- 暂停 -->
      <div v-if="!st.enabled" class="pause">提醒已暂停 · 去右下角托盘恢复</div>

      <template v-else>

        <!-- 休息中 -->
        <div v-if="st.resting" class="rest-card">
          <div class="rest-tag">{{ st.activeName }} · 眼睛休息时间</div>
          <div class="rest-num">{{ fmt(st.remaining) }}</div>
          <div class="rest-bar-w"><div class="rest-bar-f" :style="{ width: pPct + '%' }"></div></div>
          <div class="rest-msg">{{ st.message }}</div>
          <button class="btn btn-p" @click="doSkip">跳过休息</button>
        </div>

        <!-- 空闲双计时 -->
        <div v-else class="dual">
          <div class="dual-c dual-s">
            <div class="dual-h"><span class="dual-ic">☕</span> 小休息</div>
            <div class="dual-t">{{ fmt(st.shortRemaining) }}</div>
            <div class="dual-b"><div class="dual-bf" :style="{ width: sPct + '%' }"></div></div>
            <div class="dual-sub">~{{ fmt(st.shortTotal) }}</div>
          </div>
          <div class="dual-div"></div>
          <div class="dual-c dual-l">
            <div class="dual-h"><span class="dual-ic">🧘</span> 大休息</div>
            <div class="dual-t">{{ fmt(st.longRemaining) }}</div>
            <div class="dual-b"><div class="dual-bf" :style="{ width: lPct + '%' }"></div></div>
            <div class="dual-sub">~{{ fmt(st.longTotal) }}</div>
          </div>
        </div>

        <!-- 下一个 -->
        <div v-if="!st.resting" class="next">下一个：{{ st.nextName }} · {{ fmt(st.nextSeconds) }}</div>
      </template>

      <!-- 操作行 -->
      <div v-if="!st.resting && st.enabled" class="actions">
        <button class="btn btn-ghost" @click="doReset">重置计时</button>
        <button class="btn btn-ghost" @click="showSet = !showSet">{{ showSet ? '收起' : '设置' }}</button>
      </div>

      <!-- 设置 -->
      <div v-if="showSet && !st.resting" class="set">
        <div class="sr"><span class="sr-l">小休息间隔</span><input type="text" inputmode="numeric" :value="s.shortIntervalMinutes" @change="save('shortIntervalMinutes', $event.target.value)" /><span class="sr-u">分钟</span></div>
        <div class="sr"><span class="sr-l">小休息时长</span><input type="text" inputmode="numeric" :value="s.shortDurationSeconds" @change="save('shortDurationSeconds', $event.target.value)" /><span class="sr-u">秒</span></div>
        <div class="sr"><span class="sr-l">大休息间隔</span><input type="text" inputmode="numeric" :value="s.longIntervalMinutes" @change="save('longIntervalMinutes', $event.target.value)" /><span class="sr-u">分钟</span></div>
        <div class="sr"><span class="sr-l">大休息时长</span><input type="text" inputmode="numeric" :value="s.longDurationMinutes" @change="save('longDurationMinutes', $event.target.value)" /><span class="sr-u">分钟</span></div>
      </div>
    </div>

    <!-- === 底部 === -->
    <div class="foot">
      <span>关闭窗口仍在后台运行，右键系统托盘操作</span>
      <button class="btn btn-exit" @click="exit">退出</button>
    </div>
  </div>

  <!-- === 全屏覆盖层 === -->
  <div v-if="overlay" class="ol" @keydown.escape="skipOver" @click="skipOver" tabindex="0">
    <div class="ol-c">
      <div class="ol-msg">{{ st.message }}</div>
      <div class="ol-num">{{ fmt(st.remaining) }}</div>
      <div class="ol-b"><div class="ol-bf" :style="{ width: pPct + '%' }"></div></div>
      <button class="btn ol-btn" @click.stop="skipOver">跳过本次休息</button>
    </div>
  </div>
</template>

<style scoped>
/* ========== Reset ========== */
.app { height: 100vh; display: flex; flex-direction: column; background: linear-gradient(135deg, #f8f9fc 0%, #eef1f6 100%); user-select: none; overflow: hidden; }
.body { flex: 1; padding: 4px 24px 12px; display: flex; flex-direction: column; overflow-y: auto; gap: 6px; }

/* ========== Header ========== */
.head { display: flex; align-items: center; justify-content: space-between; padding: 12px 24px 6px; }
.head-left { display: flex; align-items: center; gap: 8px; }
.logo { font-size: 22px; }
.head-title { font-size: 17px; font-weight: 700; color: #1a1a2e; letter-spacing: 0.3px; }

/* Toggle */
.tg { position: relative; width: 40px; height: 22px; cursor: pointer; flex-shrink: 0; }
.tg input { display: none; }
.tg-sl {
  position: absolute; inset: 0; background: #c8cdd5; border-radius: 22px; transition: 0.25s;
  box-shadow: inset 0 1px 3px rgba(0,0,0,0.1);
}
.tg-sl::before {
  content: ''; position: absolute; width: 16px; height: 16px; left: 3px; top: 3px;
  background: white; border-radius: 50%; transition: 0.25s; box-shadow: 0 1px 3px rgba(0,0,0,0.15);
}
.tg input:checked + .tg-sl { background: #4361ee; }
.tg input:checked + .tg-sl::before { transform: translateX(18px); }

/* ========== Pause ========== */
.pause { text-align: center; color: #888; font-size: 15px; margin-top: 40px; }

/* ========== Rest card ========== */
.rest-card { text-align: center; padding: 16px 0 8px; }
.rest-tag { font-size: 14px; color: #4361ee; font-weight: 600; margin-bottom: 2px; letter-spacing: 0.5px; }
.rest-num { font-size: 56px; font-weight: 800; color: #1a1a2e; font-variant-numeric: tabular-nums; margin: 10px 0; letter-spacing: -1px; line-height: 1; }
.rest-bar-w { height: 6px; background: #e2e5ec; border-radius: 3px; overflow: hidden; margin: 0 auto 12px; max-width: 300px; }
.rest-bar-f { height: 100%; background: linear-gradient(90deg, #4361ee, #7b2ff7); border-radius: 3px; transition: width 0.3s; }
.rest-msg { font-size: 15px; color: #666; margin-bottom: 14px; }

/* ========== Dual cards ========== */
.dual { display: flex; gap: 16px; margin: 8px 0 2px; }
.dual-c { flex: 1; background: white; border-radius: 12px; padding: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
.dual-h { font-size: 14px; font-weight: 600; color: #444; margin-bottom: 8px; }
.dual-ic { font-size: 18px; }
.dual-t { font-size: 28px; font-weight: 800; color: #1a1a2e; font-variant-numeric: tabular-nums; margin-bottom: 8px; }
.dual-b { height: 5px; background: #e8eaef; border-radius: 3px; overflow: hidden; margin-bottom: 4px; }
.dual-bf { height: 100%; border-radius: 3px; transition: width 0.3s; }
.dual-s .dual-bf { background: linear-gradient(90deg, #43a6ee, #4361ee); }
.dual-l .dual-bf { background: linear-gradient(90deg, #7b2ff7, #c13584); }
.dual-sub { font-size: 11px; color: #aaa; font-variant-numeric: tabular-nums; }

.dual-div { width: 0; }

.next { text-align: center; font-size: 13px; color: #888; margin: 4px 0; }

/* ========== Actions ========== */
.actions { display: flex; gap: 12px; margin-top: 2px; }

/* ========== Settings ========== */
.set { display: flex; flex-direction: column; gap: 4px; padding: 10px 14px; background: white; border-radius: 10px; box-shadow: 0 1px 6px rgba(0,0,0,0.04); margin-top: 2px; }
.sr { display: flex; align-items: center; gap: 8px; font-size: 13px; }
.sr-l { width: 86px; color: #555; }
.sr input {
  width: 68px; padding: 4px 6px; border: 1px solid #d4d8e0; border-radius: 6px;
  text-align: right; font-size: 13px; outline: none; color: #333; background: #f8f9fc;
  -moz-appearance: textfield;
}
.sr input::-webkit-inner-spin-button, .sr input::-webkit-outer-spin-button { -webkit-appearance: none; margin: 0; }
.sr input:focus { border-color: #4361ee; box-shadow: 0 0 0 2px rgba(67,97,238,0.12); }
.sr-u { color: #999; font-size: 12px; }

/* ========== Buttons ========== */
.btn { border: none; cursor: pointer; border-radius: 8px; transition: 0.15s; font-size: 14px; font-weight: 500; }
.btn-p { background: linear-gradient(135deg, #4361ee, #7b2ff7); color: white; padding: 10px 28px; font-size: 15px; box-shadow: 0 2px 8px rgba(67,97,238,0.3); }
.btn-p:hover { transform: translateY(-1px); box-shadow: 0 4px 14px rgba(67,97,238,0.35); }
.btn-ghost { background: white; color: #555; padding: 6px 14px; border: 1px solid #e2e5ec; font-size: 13px; }
.btn-ghost:hover { background: #f0f2f7; border-color: #c8cdd5; }
.btn-exit { background: none; color: #bbb; padding: 0; font-size: 11px; }
.btn-exit:hover { color: #e74c3c; }

/* ========== Footer ========== */
.foot { display: flex; justify-content: space-between; align-items: center; padding: 8px 24px 12px; font-size: 11px; color: #bbb; }

/* ========== Overlay ========== */
.ol {
  position: fixed; inset: 0; z-index: 99999; background: #000;
  display: flex; align-items: center; justify-content: center; color: #aaa; cursor: pointer;
}
.ol-c { text-align: center; max-width: 700px; padding: 40px; cursor: default; }
.ol-msg { font-size: 26px; font-weight: 500; margin-bottom: 20px; color: #ccc; }
.ol-num { font-size: 72px; font-weight: 700; font-variant-numeric: tabular-nums; margin-bottom: 16px; color: #eee; letter-spacing: -2px; }
.ol-b { width: 400px; height: 5px; margin: 0 auto 20px; background: #222; border-radius: 3px; overflow: hidden; }
.ol-bf { height: 100%; background: linear-gradient(90deg, #555, #888); border-radius: 3px; transition: width 0.2s; }
.ol-btn { font-size: 15px; padding: 10px 28px; background: #222; color: #aaa; }
.ol-btn:hover { background: #333; color: #ddd; }
</style>
