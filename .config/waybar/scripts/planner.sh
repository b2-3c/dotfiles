#!/bin/bash

# ─────────────────────────────────────────────
#  Planner — Unified Todo + Countdown for Waybar
# ─────────────────────────────────────────────

TODO_DIR="$HOME/.config/waybar/scripts/todo"
COUNTDOWN_DIR="$HOME/.config/waybar/scripts/countdown"
TODO_JSON="$TODO_DIR/todo.json"
COUNTDOWN_JSON="$COUNTDOWN_DIR/countdown.json"

# Colors
PENDING_COLOR="#cdd6f4"
DONE_COLOR="#cdd6f4"
EXPIRED_COLOR="#cdd6f4"
COUNTDOWN_COLOR="#cdd6f4"
SEP_COLOR="#6c7086"

# ─── ensure json files exist ───────────────────

ensure_files() {
    if [[ ! -f "$TODO_JSON" ]]; then
        mkdir -p "$TODO_DIR"
        echo '{"config":{"scheduled_time":"none","scheduled_action":"none","last_checked_timestamp":0,"middle_click_action":"none"},"tasks":[]}' > "$TODO_JSON"
    fi
    if [[ ! -f "$COUNTDOWN_JSON" ]]; then
        mkdir -p "$COUNTDOWN_DIR"
        echo '{"state":{"current_index":0},"countdowns":[]}' > "$COUNTDOWN_JSON"
    fi
}

# ─── todo helpers ──────────────────────────────

get_todo_summary() {
    local pending total
    pending=$(jq '[.tasks[] | select(.status == 0)] | length' "$TODO_JSON")
    total=$(jq '.tasks | length' "$TODO_JSON")
    echo "$pending/$total"
}

get_first_todo() {
    jq -r '[.tasks | sort_by(.priority)[] | select(.status == 0)] | first | .description // ""' "$TODO_JSON"
}

# ─── countdown helpers ─────────────────────────

get_countdown_summary() {
    local count now_secs active expired
    count=$(jq '.countdowns | length' "$COUNTDOWN_JSON")
    if [[ "$count" -eq 0 ]]; then echo "0"; return; fi

    now_secs=$(date +%s)
    active=0
    expired=0

    while IFS=$'\t' read -r end_date; do
        local end_secs
        end_secs=$(date -d "$end_date" +%s 2>/dev/null)
        if [[ -n "$end_secs" ]]; then
            if [[ "$now_secs" -ge "$end_secs" ]]; then
                ((expired++))
            else
                ((active++))
            fi
        fi
    done < <(jq -r '.countdowns[] | .end' "$COUNTDOWN_JSON")

    echo "${active}a/${expired}e"
}

get_nearest_countdown() {
    local now_secs
    now_secs=$(date +%s)
    local nearest_label="" nearest_days=9999999

    while IFS=$'\t' read -r label end_date; do
        local end_secs
        end_secs=$(date -d "$end_date" +%s 2>/dev/null)
        [[ -z "$end_secs" ]] && continue
        if [[ "$now_secs" -lt "$end_secs" ]]; then
            local days=$(( (end_secs - now_secs) / 86400 ))
            if [[ "$days" -lt "$nearest_days" ]]; then
                nearest_days=$days
                nearest_label="$label"
            fi
        fi
    done < <(jq -r '.countdowns[] | "\(.label)\t\(.end)"' "$COUNTDOWN_JSON")

    if [[ -n "$nearest_label" ]]; then
        echo "${nearest_label} · ${nearest_days}d"
    else
        echo ""
    fi
}

# ─── build bar text ────────────────────────────

build_bar_text() {
    local todo_pending total first_task countdown_near

    todo_pending=$(jq '[.tasks[] | select(.status == 0)] | length' "$TODO_JSON")
    total=$(jq '.tasks | length' "$TODO_JSON")
    first_task=$(get_first_todo)
    countdown_near=$(get_nearest_countdown)

    local text=""

    # Todo part
    if [[ "$total" -eq 0 ]]; then
        text=" No tasks"
    elif [[ "$todo_pending" -eq 0 ]]; then
        text=" ✔ All done!"
    else
        local short_task
        if [[ ${#first_task} -gt 18 ]]; then
            short_task="${first_task:0:16}…"
        else
            short_task="$first_task"
        fi
        text=" ${todo_pending}  ${short_task}"
    fi

    # Countdown separator + part
    if [[ -n "$countdown_near" ]]; then
        text="${text}  󰅐 ${countdown_near}"
    fi

    echo "$text"
}

# ─── build tooltip ─────────────────────────────

build_tooltip() {
    local tooltip=""

    # ── TODO section ──
    tooltip+="<b><u> Todo List</u></b>\n"

    local task_count
    task_count=$(jq '.tasks | length' "$TODO_JSON")

    if [[ "$task_count" -eq 0 ]]; then
        tooltip+="  <span color='${SEP_COLOR}'>No tasks yet — right-click to add!</span>\n"
    else
        local pending_block="" done_block=""

        while IFS=$'\t' read -r status desc; do
            if [[ "$status" -eq 1 ]]; then
                done_block+="  <span color='${DONE_COLOR}'>✔ <s>${desc}</s></span>\n"
            else
                pending_block+="  <span color='${PENDING_COLOR}'>● ${desc}</span>\n"
            fi
        done < <(jq -r '.tasks | sort_by(.priority)[] | "\(.status)\t\(.description)"' "$TODO_JSON")

        [[ -n "$pending_block" ]] && tooltip+="$pending_block"
        [[ -n "$done_block" ]] && tooltip+="\n$done_block"
    fi

    tooltip+="\n"

    # ── COUNTDOWN section ──
    tooltip+="<b><u>󰅐 Countdowns</u></b>\n"

    local cd_count
    cd_count=$(jq '.countdowns | length' "$COUNTDOWN_JSON")

    if [[ "$cd_count" -eq 0 ]]; then
        tooltip+="  <span color='${SEP_COLOR}'>No countdowns — right-click to add!</span>\n"
    else
        local now_secs
        now_secs=$(date +%s)

        while IFS=$'\t' read -r label end_date; do
            local end_secs
            end_secs=$(date -d "$end_date" +%s 2>/dev/null)
            if [[ -z "$end_secs" ]]; then
                tooltip+="  <span color='${SEP_COLOR}'>${label} — invalid date</span>\n"
                continue
            fi
            if [[ "$now_secs" -ge "$end_secs" ]]; then
                tooltip+="  <span color='${EXPIRED_COLOR}'>✗ ${label} — Expired!</span>\n"
            else
                local days=$(( (end_secs - now_secs) / 86400 ))
                tooltip+="  <span color='${COUNTDOWN_COLOR}'>󰅐 ${label} — ${days} days left</span>\n"
            fi
        done < <(jq -r '.countdowns[] | "\(.label)\t\(.end)"' "$COUNTDOWN_JSON")
    fi

    tooltip+="\n<span color='${SEP_COLOR}'>Left-click: Todo menu   Right-click: Countdown menu</span>"

    # Return raw — jq in generate_output handles escaping
    echo -e "$tooltip"
}

# ─── css class ─────────────────────────────────

build_class() {
    local pending expired
    pending=$(jq '[.tasks[] | select(.status == 0)] | length' "$TODO_JSON")
    local now_secs
    now_secs=$(date +%s)
    expired=$(jq --argjson now "$now_secs" \
        '[.countdowns[] | select(((.end | strptime("%Y-%m-%d") | mktime) <= $now))] | length' \
        "$COUNTDOWN_JSON" 2>/dev/null || echo 0)

    if [[ "$expired" -gt 0 ]]; then
        echo "expired"
    elif [[ "$pending" -gt 0 ]]; then
        echo "pending"
    else
        echo "done"
    fi
}

# ─── waybar output ─────────────────────────────

generate_output() {
    local text tooltip class
    text=$(build_bar_text)
    tooltip=$(build_tooltip)
    class=$(build_class)

    jq -cn \
        --arg t "$text" \
        --arg tt "$tooltip" \
        --arg c "$class" \
        '{"text":$t,"tooltip":$tt,"class":$c}'
}

# ─── argument handling ─────────────────────────

ensure_files

case "$1" in
    --todo-rofi)
        # Variables required by todo_rofi.sh
        todo_dir="$TODO_DIR"
        json_file="$TODO_JSON"
        primary_color="$DONE_COLOR"
        secondary_color="$PENDING_COLOR"
        done_color="$DONE_COLOR"
        pending_color="$PENDING_COLOR"
        tui_script="$TODO_DIR/todo_tui.sh"
        rofi_script="$TODO_DIR/todo_rofi.sh"

        # Functions from todo.sh needed by todo_rofi.sh
        ensure_json_exists() {
            if [[ ! -f "$json_file" ]]; then
                echo '{"config":{"scheduled_time":"none","scheduled_action":"none","last_checked_timestamp":0,"middle_click_action":"none"},"tasks":[]}' > "$json_file"
            fi
        }
        get_config() {
            jq -r ".config.$1" "$json_file"
        }
        update_config() {
            local tmp=$(mktemp)
            jq --arg k "$1" --arg v "$2" '.config[$k] = $v' "$json_file" > "$tmp" && mv "$tmp" "$json_file"
        }
        json_add_task() {
            local prio="$1" desc="$2" insert_mode="$3" tmp=$(mktemp)
            jq --argjson p "$prio" --arg d "$desc" --argjson insert "$insert_mode" '
                (if $insert then $p else $p + 1 end) as $target_p |
                .tasks |= map(
                    if $insert then
                        if .priority >= $p then .priority += 1 else . end
                    else
                        if .priority > $p then .priority += 1 else . end
                    end
                ) |
                .tasks += [{"priority": $target_p, "status": 0, "description": $d}] |
                .tasks |= sort_by(.priority)
            ' "$json_file" > "$tmp" && mv "$tmp" "$json_file"
        }
        json_delete_task() {
            local tmp=$(mktemp)
            jq --argjson i "$1" '.tasks |= sort_by(.priority) | del(.tasks[$i])' "$json_file" > "$tmp" && mv "$tmp" "$json_file"
        }
        json_toggle_task() {
            local tmp=$(mktemp)
            jq --argjson i "$1" '
                .tasks |= sort_by(.priority) |
                .tasks[$i].status = (if .tasks[$i].status == 0 then 1 else 0 end)
            ' "$json_file" > "$tmp" && mv "$tmp" "$json_file"
        }

        source "$TODO_DIR/todo_rofi.sh"
        run_rofi_main
        exit 0
        ;;
    --countdown-rofi)
        # Variables required by countdown_rofi.sh
        script_dir="$COUNTDOWN_DIR"
        data_file="$COUNTDOWN_JSON"
        expired_color="$EXPIRED_COLOR"
        seperator_color="$COUNTDOWN_COLOR"
        source "$COUNTDOWN_DIR/countdown_rofi.sh"
        # Functions from countdown.sh needed by rofi
        get_countdown_count() { jq '.countdowns | length' "$data_file"; }
        json_add_countdown() {
            local lbl="$1" start="$2" end="$3" fmt="$4" tmp=$(mktemp)
            jq --arg l "$lbl" --arg s "$start" --arg e "$end" --arg f "$fmt" \
                '.countdowns += [{"label":$l,"start":$s,"end":$e,"format":$f}]' "$data_file" > "$tmp" && mv "$tmp" "$data_file"
        }
        json_edit_countdown() {
            local idx="$1" lbl="$2" start="$3" end="$4" fmt="$5" tmp=$(mktemp)
            jq --argjson i "$idx" --arg l "$lbl" --arg s "$start" --arg e "$end" --arg f "$fmt" \
                '.countdowns[$i] = {"label":$l,"start":$s,"end":$e,"format":$f}' "$data_file" > "$tmp" && mv "$tmp" "$data_file"
        }
        json_delete_countdown() {
            local idx="$1" tmp=$(mktemp)
            jq --argjson i "$idx" 'del(.countdowns[$i])' "$data_file" > "$tmp" && mv "$tmp" "$data_file"
        }
        show_rofi_menu
        exit 0
        ;;
    --mark-done)
        tmp=$(mktemp)
        jq '.tasks |= sort_by(.priority) |
            (.tasks | map(.status == 0) | index(true)) as $idx |
            if $idx != null then .tasks[$idx].status = 1 else . end' \
            "$TODO_JSON" > "$tmp" && mv "$tmp" "$TODO_JSON"
        exit 0
        ;;
    --scroll-up)
        count=$(jq '.countdowns | length' "$COUNTDOWN_JSON")
        if [[ "$count" -gt 1 ]]; then
            curr=$(jq '.state.current_index // 0' "$COUNTDOWN_JSON")
            new=$(( (curr - 1 + count) % count ))
            tmp=$(mktemp)
            jq --argjson i "$new" '.state.current_index = $i' "$COUNTDOWN_JSON" > "$tmp" && mv "$tmp" "$COUNTDOWN_JSON"
        fi
        exit 0
        ;;
    --scroll-down)
        count=$(jq '.countdowns | length' "$COUNTDOWN_JSON")
        if [[ "$count" -gt 1 ]]; then
            curr=$(jq '.state.current_index // 0' "$COUNTDOWN_JSON")
            new=$(( (curr + 1) % count ))
            tmp=$(mktemp)
            jq --argjson i "$new" '.state.current_index = $i' "$COUNTDOWN_JSON" > "$tmp" && mv "$tmp" "$COUNTDOWN_JSON"
        fi
        exit 0
        ;;
esac

generate_output
