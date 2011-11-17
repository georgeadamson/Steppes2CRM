﻿/*
* jQuery Callout 0.1
* Copyright (c) 2008 David Von Lehman
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

(function($) { $.fn.callout = function(settings) { settings = $.extend({ orient: "above", align: "left", text: "", arrowHeight: 10, nudgeHorizontal: 0, nudgeVertical: 0, arrowInset: 20, cornerRadius: 3, region: undefined }, settings || {}); settings.target = $(this).filter(":first"); if (settings.target.length === 0 || settings.target.data("__callout") != null) { return; } var htmlContent = settings.content ? $(settings.content).html() : (settings.text || ""); var dummy = $("<div/>").css({ "position": "absolute", "visibility": "hidden" }).attr("class", settings.className).html(htmlContent).prependTo("body"); if (settings.cornerRadius > 0) { $.each(["top", "left", "bottom", "right"], function(i, val) { dummy.css("padding-" + val, Math.max(dummy.pixels("padding-" + val), settings.cornerRadius)); }); } settings = $.extend(settings, { borderColor: $(dummy).css("border-top-color"), borderWidth: $(dummy).pixels("border-top-width"), backColor: $(dummy).css("background-color"), zIndex: parseInt($(dummy).css("z-index"), 0), paddingTop: dummy.pixels("padding-top"), paddingBottom: dummy.pixels("padding-bottom"), paddingLeft: dummy.pixels("padding-left"), paddingRight: dummy.pixels("padding-right") }); dummy.width(settings.width - dummy.pixels("padding-left") - dummy.pixels("padding-right") - 2 * settings.borderWidth); if (settings.zIndex === 0 || isNaN(settings.zIndex)) { settings.zIndex = 9999; } settings.mainHeight = dummy.height() + settings.paddingTop + settings.paddingBottom + 2 * settings.borderWidth; settings.height = settings.mainHeight + settings.arrowHeight + settings.borderWidth; if (($.browser.msie || $.browser.chrome) && settings.cornerRadius > 0) { settings.paddingTop -= (settings.cornerRadius - settings.borderWidth); settings.paddingBottom -= (settings.cornerRadius - settings.borderWidth); } $(dummy).remove(); var containerBox = $("<div />").attr("id", $(this).attr("id") + "_callout").css({ "position": "absolute", "display": "none", "z-index": settings.zIndex, "background-color": settings.region ? $(settings.region).css("background-color") : "transparent" }).prependTo(settings.region ? settings.region : "body"); var mainBox = $("<div />").attr("id", "mainBox").css({ "position": "absolute", "background-color": settings.borderWidth > 0 ? settings.borderColor : "transparent", "z-index": settings.zIndex }).width(settings.width).appendTo(containerBox); var contentBox = $("<div/>").attr("id", "contentBox").css({ "position": "absolute", "background-color": settings.backColor, "margin-left": settings.borderWidth + "px", "margin-top": settings.borderWidth + "px", "z-index": settings.zIndex }).width(settings.width - 2 * settings.borderWidth).appendTo(mainBox); var contentInnerBox = $("<div/>").attr("class", settings.className).css({ "border": "none", "width": "auto", "margin-top": settings.paddingTop + "px", "margin-bottom": settings.paddingBottom + "px", "margin-left": settings.paddingLeft + "px", "margin-right": settings.paddingRight + "px", "overflow": "hidden", "padding": "0 0 0 0" }).html(htmlContent).appendTo(contentBox); if (!$.browser.msie && !$.browser.chrome) { contentInnerBox.height(settings.mainHeight - 2 * settings.borderWidth - settings.paddingTop - settings.paddingBottom); } settings.targetOffset = settings.target.offset(); if (settings.align.toLowerCase() == "right") { settings.arrowLeft = settings.width - settings.arrowHeight - settings.arrowInset - settings.paddingRight; settings.offsetLeft = settings.targetOffset.left + settings.nudgeHorizontal + settings.target.width() - settings.width; } else { settings.arrowLeft = settings.arrowInset; settings.offsetLeft = settings.targetOffset.left + settings.nudgeHorizontal; } var arrowDiv = $("<div />").css({ "position": "absolute", "width": "0px", "height": "0px", "left": "0px", "top": "0px", "border-left-style": "dotted", "border-left-color": "transparent", "border-right-style": "dotted", "border-right-color": "transparent", "margin-left": settings.arrowLeft + "px", "z-index": settings.zIndex + 2, "border-width": (2 * settings.borderWidth + settings.arrowHeight) + "px" }); var arrowDivInner = $("<div />").css({ "position": "relative", "left": -1 * settings.arrowHeight + "px", "height": "0px", "width": "0px", "border-width": settings.arrowHeight + "px", "border-left-style": "dotted", "border-right-style": "dotted", "border-left-color": "transparent", "border-right-color": "transparent", "z-index": settings.zIndex + 1 }).appendTo(arrowDiv); if (settings.orient.toLowerCase() == "below") { $(arrowDiv).css({ "border-top": "none", "border-bottom": "solid " + (settings.arrowHeight + 2 * settings.borderWidth) + "px " + settings.borderColor, "top": "0px" }).prependTo(mainBox); $(arrowDivInner).css({ "border-top-style": "none", "top": 2 * settings.borderWidth + "px", "border-bottom": settings.arrowHeight + "px solid " + settings.backColor }); contentBox.css("top", settings.arrowHeight + settings.borderWidth); settings.offsetTop = settings.targetOffset.top + settings.target.height() + settings.nudgeVertical; } else { $(arrowDiv).css({ "border-bottom": "none", "border-top-style": "solid", "border-top-width": (settings.arrowHeight + 2 * settings.borderWidth) + "px", "border-top-color": settings.borderColor, "top": settings.mainHeight - settings.borderWidth + "px" }).appendTo(mainBox); $(arrowDivInner).css({ "border-bottom-style": "none", "top": -1 * (2 * settings.borderWidth + settings.arrowHeight) + "px", "border-top": settings.arrowHeight + "px solid " + settings.backColor }); settings.offsetTop = settings.targetOffset.top - (settings.mainHeight + settings.arrowHeight) + settings.nudgeVertical; } if (settings.borderWidth > 0) { var borderBox = $("<div />").width(settings.width).css({ "position": "absolute", "display": "none", "z-index": settings.zIndex - 1, "background-color": settings.borderColor, "left": settings.offsetLeft + "px", "top": settings.offsetTop + (settings.orient == "below" ? settings.arrowHeight + settings.borderWidth : 0) + "px" }).prependTo(settings.region ? settings.region : "body"); var shimHeight = settings.mainHeight; if ($.browser.msie || $.browser.chrome) { shimHeight -= (2 * settings.cornerRadius); } borderBox.append($("<div />").height(shimHeight)); } $(containerBox).css({ "left": settings.offsetLeft + "px", "top": settings.offsetTop + "px" }); if (settings.cornerRadius > 0) { if (borderBox) { borderBox.corners(settings.cornerRadius + "px"); $(contentBox).corners(settings.cornerRadius - settings.borderWidth + "px"); settings.borderBox = borderBox; } else { $(contentBox).corners(settings.cornerRadius + "px"); } } if (typeof (settings.showCallback) == "function") { settings.showCallback.apply(containerBox, [settings]); } else { containerBox.show(); if (borderBox) { borderBox.show(); } } settings.target.data("__callout", [containerBox, borderBox]); return this; }; $.browser.chrome = navigator.userAgent.toLowerCase().indexOf('chrome') > -1; $.fn.pixels = function(cssAttr) { var val = $(this).css(cssAttr); var i = val.indexOf("px"); if (i == -1) { return 0; } return parseFloat(val.substr(0, i)); }; $.fn.closeCallout = function() { return $(this).each(function() { var calloutSet = $(this).data("__callout"); if (calloutSet == null) { return; } $.each(calloutSet, function() { $(this).remove(); }); $(this).data("__callout", null); }); }; })(jQuery);