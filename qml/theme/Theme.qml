pragma Singleton
import QtQuick

/*
 * Sistema de diseño de REP.
 *
 * Única fuente de verdad para colores, tipografía, espaciado y radios. Las páginas
 * no deben usar colores hexadecimales directamente: así el aspecto es coherente y
 * puede ajustarse (o añadirse un modo oscuro) en un solo lugar.
 */
QtObject {
    // ---- Marca ----
    readonly property color primary: "#4F46E5"
    readonly property color primaryDark: "#4338CA"
    readonly property color primarySoft: "#EEF2FF"
    readonly property color accent: "#0EA5E9"

    // ---- Superficies ----
    readonly property color background: "#F1F5F9"
    readonly property color surface: "#FFFFFF"
    readonly property color surfaceAlt: "#F8FAFC"
    readonly property color surfaceDark: "#1E293B"
    readonly property color sidebar: "#0F172A"
    readonly property color border: "#E2E8F0"
    readonly property color borderStrong: "#CBD5E1"

    // ---- Texto ----
    readonly property color textPrimary: "#0F172A"
    readonly property color textSecondary: "#64748B"
    readonly property color textMuted: "#94A3B8"
    readonly property color textOnPrimary: "#FFFFFF"
    readonly property color textOnDark: "#E2E8F0"

    // ---- Estados ----
    readonly property color success: "#16A34A"
    readonly property color successDark: "#15803D"
    readonly property color successSoft: "#DCFCE7"
    readonly property color warning: "#D97706"
    readonly property color warningSoft: "#FEF3C7"
    readonly property color danger: "#DC2626"
    readonly property color dangerDark: "#B91C1C"
    readonly property color dangerSoft: "#FEE2E2"
    readonly property color info: "#0284C7"
    readonly property color infoSoft: "#E0F2FE"
    readonly property color purple: "#7C3AED"
    readonly property color teal: "#0D9488"

    // ---- Tipografía (px) ----
    readonly property string fontFamily: "Inter, Segoe UI, Roboto, Noto Sans, sans-serif"
    readonly property int fontCaption: 12
    readonly property int fontBody: 14
    readonly property int fontSubtitle: 16
    readonly property int fontTitle: 20
    readonly property int fontHeadline: 28
    readonly property int fontDisplay: 40

    // ---- Espaciado y forma ----
    readonly property int spacingXs: 4
    readonly property int spacingS: 8
    readonly property int spacingM: 16
    readonly property int spacingL: 24
    readonly property int spacingXl: 32
    readonly property int radiusS: 6
    readonly property int radiusM: 10
    readonly property int radiusL: 16
    readonly property int controlHeight: 44
    readonly property int headerHeight: 64
    readonly property int maxContentWidth: 1200

    // ---- Movimiento ----
    readonly property int animFast: 120
    readonly property int animNormal: 200
}
