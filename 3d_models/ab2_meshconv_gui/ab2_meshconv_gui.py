#!/usr/bin/env python
# --------------------------------------------------------------------------- #
# Setup
# --------------------------------------------------------------------------- #
# Import the logging module first -- don't continue if an exception is
# encountered
try:
  import logging
except ImportError:
  print "Unable to import logging module"
  raw_input("Press Enter to continue...")
  raise SystemExit, 1

# Configure logging for the default basic configuration
logging.basicConfig()
# Create a logging object called log
log = logging.getLogger(__name__)
# Configure log level
log.setLevel(logging.DEBUG)
#log.setLevel(logging.ERROR)

# Print log level if DEBUG or lower is enabled
log.debug("Debug level: " + str(log.getEffectiveLevel()))

# Import required modules
import_success_flag = True
try:
  import gobject
  log.debug("Gobject Module Loaded")
except ImportError:
  log.exception("Gobject Module Failed To Load")
  import_success_flag = False
try:
  import gtk
  log.debug("GTK Module Loaded")
except ImportError:
  log.exception("GTK Module Failed To Load")
  import_success_flag = False
try:
  import os
  log.debug("OS Module Loaded")
except ImportError:
  log.exception("OS Module Failed To Load")
  import_success_flag = False
try:
  import pygtk
  pygtk.require("2.0")
  log.debug("PyGTK Module Loaded")
except ImportError:
  import_success_flag = False
  log.exception("PyGTK Module Failed To Load")
  import_success_flag = False
try:
  import subprocess
  log.debug("Subprocess Module Loaded")
except ImportError:
  log.exception("Subprocess Module Failed To Load")
  import_success_flag = False
try:
  import sys
  log.debug("Sys Module Loaded")
except ImportError:
  log.exception("Sys Module Failed To Load")
  import_success_flag = False
try:
  import time
  log.debug("Time Module Loaded")
except ImportError:
  log.exception("Time Module Failed To Load")
  import_success_flag = False
try:
  import webbrowser
  log.debug("Webbrowser Module Loaded")
except ImportError:
  import_success_flag = False
  log.debug("Webbrowser Module Failed To Load")

if not import_success_flag:
  log.error("Some module(s) failed to load")
  raw_input("Press Enter to continue...")
  raise SystemExit, 1
log.debug("")

################################################################################
################################################################################
class AB2TECH:
  def __init__(self):
    directory = os.path.realpath(os.path.dirname(sys.argv[0]))
    # AB2Tech Icon
    self.logo = gtk.Image()
    pixbuf_logo = gtk.gdk.pixbuf_new_from_file(
      os.path.join(directory, "AB2Tech_300.png"))
    self.scaled_logo = pixbuf_logo.scale_simple(
      100, 79, gtk.gdk.INTERP_BILINEAR)
    self.logo.set_from_pixbuf(self.scaled_logo)

    # AB2Tech URLs
    self.url_main          = "http://ab2tech.com/"
    self.url_github        = "https://github.com/ab2tech"
    self.url_github_kicad  = "https://github.com/ab2tech/KiCad"
    self.url_github_msp430 = "https://github.com/ab2tech/msp430"

class AB2TECH_SIGNOFF(gtk.Dialog):
  def __init__(self):
    gtk.Dialog.__init__(
      self,
      title = "AB2Tech Thanks You",
      parent = None,
      flags = gtk.DIALOG_MODAL,
      buttons = (gtk.STOCK_OK, gtk.RESPONSE_ACCEPT))
    self.set_position(gtk.WIN_POS_CENTER)
    self.set_border_width(5)
    self.set_icon(ab2tech.scaled_logo)

    self.action_area.set_layout(gtk.BUTTONBOX_SPREAD)
    self.action_area.get_children()[0].grab_focus()

    self.vbox.set_spacing(5)
    self.vbox.pack_start(ab2tech.logo)
    link_button_main = gtk.LinkButton(ab2tech.url_main,"AB2Tech Website")
    link_button_git = gtk.LinkButton(ab2tech.url_github,"AB2Tech GitHub")
    ####HACK####
    link_button_main.connect("clicked", interwebs, ab2tech.url_main)
    link_button_git.connect("clicked", interwebs, ab2tech.url_github)
    ####HACK####
    self.vbox.pack_start(link_button_main,  5)
    self.vbox.pack_start(link_button_git)
    self.vbox.pack_start(gtk.Label("Thank you for your interest and support"))
    self.show_all()

    self.close_timeout = gobject.timeout_add(1750, self.close)
    response = self.run()
    self.close

  def close(self):
    gobject.source_remove(self.close_timeout)
    self.destroy()


class AB2TECH_MESHCONV_GUI(gtk.FileChooserDialog):
  def __init__(self):
    gtk.FileChooserDialog.__init__(
      self,
      title = "Select OpenSCAD.stl File to Convert",
      parent = None,
      action = gtk.FILE_CHOOSER_ACTION_OPEN,
      buttons = (gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,
                 gtk.STOCK_OPEN, gtk.RESPONSE_OK),
      backend = None)
    self.set_default_response(gtk.RESPONSE_OK)

    print sys.argv
    print sys.argv[0]
    print os.path.dirname(sys.argv[0])
    print os.path.realpath(os.path.dirname(sys.argv[0]))
    print os.path.abspath(os.path.join(os.path.dirname(sys.argv[0]),os.pardir))

    self.set_current_folder(os.path.abspath(
      os.path.join(os.path.dirname(sys.argv[0]),os.pardir)))

    file_filter = gtk.FileFilter()
    file_filter.set_name("STL")
    file_filter.add_pattern("*.stl")
    self.add_filter(file_filter)

    self.set_icon(ab2tech.scaled_logo)
    self.set_position(gtk.WIN_POS_CENTER)

    response = self.run()

    if response == gtk.RESPONSE_OK:
      input_file = self.get_filename()

      ## Modify to fit your naming conventions
      ## OPENSCAD.stl
      ## 123456789012 = 12
      output_file = input_file[:-12] + "WINGS3D"

      command = ("meshconv.exe" +
                 " meshconv" +
                 " -c stl " + '"' + input_file + '"' +
                 " -o " + '"' + output_file + '"')

      subprocess.call(command)

    self.destroy()

################################################################################
################################################################################
def interwebs(widget, url):
  webbrowser.open_new(url)

ab2tech = AB2TECH()
ab2tech_meshconv_gui = AB2TECH_MESHCONV_GUI()
## Comment out line below if annoyed
ab2tech_signoff = AB2TECH_SIGNOFF()
