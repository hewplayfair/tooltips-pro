extends Node

# This dictionary is used to store tooltip content for text links.
# The dictionary's key is a unique ID referenced by the meta tag to get the content strings
# (ex. [url=my_unique_id]my text link[/url])

# The dictionary's value is an array of strings to be used for the tooltip's 
# content. You should only use multiple strings in the array if the TooltipTemplate's
# content_labels references enough RichTextLabels for each string.

var tooltip_meta_dictionary: Dictionary[String, Array] = {
	"example_nested":
	["This is a nested tooltip."],
	"example_pinned":
	["Opening a nested tooltip will unpin the previous one,
as only the top-most active tooltip can be pinned."],
	"example_infinite":
	["This tooltip is infinitely recursive, so you can get
an idea of how the tooltip stack works.
[tooltip=example_infinite]See next tooltip.[/tooltip]"],
	"example_rtl":
	["If the text link is not working, make sure the [b]RichTextLabel[/b]'s 
[i]Mouse > Filter[/i] is not set to [bgcolor=21262e][color=e8a3a5][code]Ignore[/code][/color][/bgcolor] or being stopped by other 
UI elements."],
	"example_settings":
	["The link settings you can change are: bold, italic, underline, color, 
background color, font, and font size"],
	"example_url":
	["The [lb]url[rb] tag is also known as a [b]meta tag[/b]. Mousing 
over it triggers the [color=c6e3fd][code]meta_hover_started[/code][/color] signal on the [b]TooltipTrigger[/b]."],
	"example_strings":
	["[b]Multiple RichTextLabels[/b]", 
	"The above title string and this one are on different [b]RichTextLabels[/b].
This allows finer control over formatting your [b]TooltipTemplate[/b]'s content."],
}
