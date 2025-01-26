using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

using System.Windows.Forms;
using ScriptPortal.Vegas;
using Newtonsoft.Json;

namespace Vegas_FX_Exporter
{
    public class EntryPoint
    {
        public void FromVegas(Vegas vegas)
        {
            //MessageBox.Show("This script will list all effects and their parameters for the currently selected event.");
            ListFX(vegas);
        }

        public void ListFX(Vegas vegas)
        {
            // Get the currently selected event
            //var tEvent = (VideoEvent)vegas.Project.Tracks[0].Events[0];
            //var tEvent = (VideoEvent)FindSelectedEvents(vegas.Project)[0];
            var selectedEvents = FindSelectedEvents(vegas.Project);
            if (selectedEvents.Length == 0)
            {
                MessageBox.Show("No events selected.", "[Martas] FX Exporter - Selection Error");
                return;
            }
            else if (selectedEvents.Length > 1)
            {
                MessageBox.Show("Please select only one event.", "[Martas] FX FX Exporter - Selection Error");
                return;
            }
            var tEvent = (VideoEvent)selectedEvents[0];
            var effectsList = new List<Dictionary<string, object>>();

            foreach (var item in tEvent.Effects)
            {
                var effectData = new Dictionary<string, object>
                {
                    { "Description", item.Description }
                };
                try
                {
                    if (!item.IsOFX)
                    {
                        effectData.Add("Type", "Non-OFX");
                        MessageBox.Show(item.PlugIn.Info);
                        continue;
                    }

                    OFXEffect fx = item.OFXEffect;
                    var parametersList = new List<Dictionary<string, object>>();

                    foreach (var param in fx.Parameters)
                    {
                        var paramData = new Dictionary<string, object>();
                        var changedValue = GetChangedParameterValue(param);
                        if (changedValue != null && !changedValue.Equals("") && param.Label != null)
                        {
                            paramData.Add("Label", param.Label);
                            paramData.Add("Value", changedValue);
                        }

                        if (param.IsAnimated)
                        {
                            if (param.Label != null)
                            {
                                paramData.Add("Label", param.Label);
                            }
                            var keyframes = GetParameterKeyframes(param);
                            if (keyframes.Count > 0)
                            {
                                paramData.Add("Keyframes", keyframes);
                            }
                        }

                        if (paramData.Count > 0)
                        {
                            parametersList.Add(paramData);
                        }
                    }

                    if (parametersList.Count > 0)
                    {
                        effectData.Add("Parameters", parametersList);
                    }
                    effectsList.Add(effectData);
                }
                catch (System.Runtime.InteropServices.COMException ex)
                {
                    //MessageBox.Show($"Error accessing {item.Description}: {ex.Message}", "[Martas] FX chain to json - Error");
                    effectsList.Add(effectData);
                    continue;
                }
            }

            string jsonOutput = JsonConvert.SerializeObject(effectsList, Formatting.Indented);
            //ShowCustomMessageBox(jsonOutput);
            PromptSaveFile(jsonOutput);
        }

        private void ShowCustomMessageBox(string message)
        {
            Form form = new Form();
            TextBox textBox = new TextBox
            {
                Multiline = true,
                ReadOnly = true,
                Dock = DockStyle.Fill,
                Text = message,//.Replace("\n", "\r\n"),
                ScrollBars = ScrollBars.Vertical
            };

            textBox.KeyDown += (sender, e) =>
            {
                if (e.Control && e.KeyCode == Keys.A)
                {
                    textBox.SelectAll();
                    e.Handled = true;
                }
            };

            form.Text = "Effects and Parameters";
            form.Controls.Add(textBox);
            form.StartPosition = FormStartPosition.CenterScreen;

            form.ShowDialog();
        }

        private void PromptSaveFile(string content)
        {
            using (SaveFileDialog saveFileDialog = new SaveFileDialog())
            {
                saveFileDialog.Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*";
                saveFileDialog.FilterIndex = 1;
                saveFileDialog.RestoreDirectory = true;

                if (saveFileDialog.ShowDialog() == DialogResult.OK)
                {
                    // Get the path of specified file
                    string filePath = saveFileDialog.FileName;

                    // Write the content to the file
                    System.IO.File.WriteAllText(filePath, content);
                }
            }
        }

        TrackEvent[] FindSelectedEvents(Project project)
        {
            List<TrackEvent> selectedEvents = new List<TrackEvent>();
            foreach (Track track in project.Tracks)
            {
                foreach (TrackEvent trackEvent in track.Events)
                {
                    if (trackEvent.Selected)
                    {
                        selectedEvents.Add(trackEvent);
                    }
                }
            }
            return selectedEvents.ToArray();
        }

        private string GetAllParameterValue(OFXParameter param) // Returns parameter value no matter if it was changed or not
        {
            string value = "";
            if (param.ParameterType == OFXParameterType.Boolean) // Boolean
            {
                value = ((OFXBooleanParameter)param).Value.ToString();
            }
            else if (param.ParameterType == OFXParameterType.Choice) // Choice
            {
                value = ((OFXChoiceParameter)param).Value.ToString();
            }
            else if (param.ParameterType == OFXParameterType.Custom) // Custom
            {
                value = ((OFXCustomParameter)param).Value.ToString();
            }
            else if (param.ParameterType == OFXParameterType.Double2D) // Double2D
            {
                value = "X:" + ((OFXDouble2DParameter)param).Value.X.ToString() + "\n" + "Y:" + ((OFXDouble2DParameter)param).Value.Y.ToString();
            }
            else if (param.ParameterType == OFXParameterType.Double3D) // Double3D
            {
                value = "X:" + ((OFXDouble3DParameter)param).Value.X.ToString() + "\n" + "Y:" + ((OFXDouble3DParameter)param).Value.Y.ToString() + "\n" + "Z:" + ((OFXDouble3DParameter)param).Value.Z.ToString();
            }
            else if (param.ParameterType == OFXParameterType.Double)    // Double
            {
                value = ((OFXDoubleParameter)param).Value.ToString();
            }
            else if (param.ParameterType == OFXParameterType.Integer)  // Integer
            {
                value = ((OFXIntegerParameter)param).Value.ToString();
            }
            else if (param.ParameterType == OFXParameterType.RGB)       // RGB
            {
                value = "R:" + ((OFXRGBParameter)param).Value.R.ToString() + "\n" + "G:" + ((OFXRGBParameter)param).Value.G.ToString() + "\n" + "B:" + ((OFXRGBParameter)param).Value.B.ToString();
            }
            else if (param.ParameterType == OFXParameterType.RGBA)      // RGBA
            {
                value = "R:" + ((OFXRGBAParameter)param).Value.R.ToString() + "\n" + "G:" + ((OFXRGBAParameter)param).Value.G.ToString() + "\n" + "B:" + ((OFXRGBAParameter)param).Value.B.ToString() + "\n" + "A:" + ((OFXRGBAParameter)param).Value.A.ToString();
            }
            else if (param.ParameterType == OFXParameterType.String)    // String
            {
                value = ((OFXStringParameter)param).Value.ToString();
            }
            else if (param.ParameterType == OFXParameterType.Integer2D) // Integer2D
            {
                value = "X:" + ((OFXInteger2DParameter)param).Value.X.ToString() + "\n" + "Y:" + ((OFXInteger2DParameter)param).Value.Y.ToString();
            }
            else if (param.ParameterType == OFXParameterType.Integer3D) // Integer3D
            {
                value = "X:" + ((OFXInteger3DParameter)param).Value.X.ToString() + "\n" + "Y:" + ((OFXInteger3DParameter)param).Value.Y.ToString() + "\n" + "Z:" + ((OFXInteger3DParameter)param).Value.Z.ToString();
            }
            else
            {
                value = "Undefined";
            }

            return value;
        }

        private object GetChangedParameterValue(OFXParameter param) // Returns parameter value only if it was changed
        {
            // string value = "";
            if (param.ParameterType == OFXParameterType.Boolean) // Boolean
            {
                var p = (OFXBooleanParameter)param;
                if (p.Value != p.Default)
                {
                    return p.Value;
                }
            }
            else if (param.ParameterType == OFXParameterType.Choice) // Choice
            {
                var p = (OFXChoiceParameter)param;
                if (p.Value != p.Default)
                {
                    return p.Value;
                }
            }
            else if (param.ParameterType == OFXParameterType.Custom) // Custom
            {
                var p = (OFXCustomParameter)param;
                if (p.Value != p.Default)
                {
                    return p.Value;
                }
            }
            else if (param.ParameterType == OFXParameterType.Double2D) // Double2D
            {
                var p = (OFXDouble2DParameter)param;
                if ((p.Value.X != p.Default.X) || (p.Value.Y != p.Default.Y))
                {
                    // value = "X:" + p.Value.X.ToString() + "\n" + "Y:" + p.Value.Y.ToString();
                    var dict = new Dictionary<string, double>
                    {
                        { "X", p.Value.X },
                        { "Y", p.Value.Y }
                    };
                    return dict;
                }
            }
            else if (param.ParameterType == OFXParameterType.Double3D) // Double3D
            {
                var p = (OFXDouble3DParameter)param;
                if ((p.Value.X != p.Default.X) || (p.Value.Y != p.Default.Y) || (p.Value.Z != p.Default.Z))
                {
                    // value = "X:" + p.Value.X.ToString() + "\n" + "Y:" + p.Value.Y.ToString() + "\n" + "Z:" + p.Value.Z.ToString();
                    var dict = new Dictionary<string, double>
                    {
                        { "X", p.Value.X },
                        { "Y", p.Value.Y },
                        { "Z", p.Value.Z }
                    };
                    return dict;
                }
            }
            else if (param.ParameterType == OFXParameterType.Double)    // Double
            {
                var p = (OFXDoubleParameter)param;
                if (p.Value != p.Default)
                {
                    // value = p.Value.ToString();
                    return p.Value;
                }
            }
            else if (param.ParameterType == OFXParameterType.Integer)  // Integer
            {
                var p = (OFXIntegerParameter)param;
                if (p.Value != p.Default)
                {
                    // value = p.Value.ToString();
                    return p.Value;
                }
            }
            else if (param.ParameterType == OFXParameterType.RGB)       // RGB
            {
                var p = (OFXRGBParameter)param;
                if ((p.Value.R != p.Default.R) || (p.Value.G != p.Default.G) || (p.Value.B != p.Default.B))
                {
                    // value = "R:" + p.Value.R.ToString() + "\n" + "G:" + p.Value.G.ToString() + "\n" + "B:" + p.Value.B.ToString();
                    var dict = new Dictionary<string, double>
                    {
                        { "R", Math.Round(p.Value.R * 255) },
                        { "G", Math.Round(p.Value.G * 255) },
                        { "B", Math.Round(p.Value.B * 255) }
                    };
                    return dict;
                }
            }
            else if (param.ParameterType == OFXParameterType.RGBA)      // RGBA
            {
                var p = (OFXRGBAParameter)param;
                if ((p.Value.R != p.Default.R) || (p.Value.G != p.Default.G) || (p.Value.B != p.Default.B) || (p.Value.A != p.Default.A))
                {
                    // value = "R:" + p.Value.R.ToString() + "\n" + "G:" + p.Value.G.ToString() + "\n" + "B:" + p.Value.B.ToString() + "\n" + "A:" + p.Value.A.ToString();
                    var dict = new Dictionary<string, double>
                    {
                        { "R", Math.Round(p.Value.R * 255) },
                        { "G", Math.Round(p.Value.G * 255) },
                        { "B", Math.Round(p.Value.B * 255) },
                        { "A", Math.Round(p.Value.A * 255) }
                    };
                    return dict;
                }
            }
            else if (param.ParameterType == OFXParameterType.String)    // String
            {
                var p = (OFXStringParameter)param;
                if (p.Value != p.Default)
                {
                    // value = p.Value.ToString();
                    return p.Value;
                }
            }
            else if (param.ParameterType == OFXParameterType.Integer2D) // Integer2D
            {
                var p = (OFXInteger2DParameter)param;
                if ((p.Value.X != p.Default.X) || (p.Value.Y != p.Default.Y))
                {
                    // value = "X:" + p.Value.X.ToString() + "\n" + "Y:" + p.Value.Y.ToString();
                    var dict = new Dictionary<string, double>
                    {
                        { "X", p.Value.X },
                        { "Y", p.Value.Y }
                    };
                    return dict;
                }
            }
            else if (param.ParameterType == OFXParameterType.Integer3D) // Integer3D
            {
                var p = (OFXInteger3DParameter)param;
                if ((p.Value.X != p.Default.X) || (p.Value.Y != p.Default.Y) || (p.Value.Z != p.Default.Z))
                {
                    // value = "X:" + p.Value.X.ToString() + "\n" + "Y:" + p.Value.Y.ToString() + "\n" + "Z:" + p.Value.Z.ToString();
                    var dict = new Dictionary<string, double>
                    {
                        { "X", p.Value.X },
                        { "Y", p.Value.Y },
                        { "Z", p.Value.Z }
                    };
                    return dict;
                }
            }
            else if (param.ParameterType == OFXParameterType.Unknown) // Unknown
            {
                return "Unknown";
            }
            else
            {
                return "";
            }
            return "";
        }

        private List<Dictionary<string, object>> GetParameterKeyframes(OFXParameter param)
        {
            var keyframesList = new List<Dictionary<string, object>>();

            if (param.ParameterType == OFXParameterType.Boolean) // Boolean
            {
                var p = (OFXBooleanParameter)param;
                foreach (var item in p.Keyframes)
                {
                    var dict = new Dictionary<string, object>
                    {
                        { "Time", item.Time },
                        { "Value", item.Value }
                    };
                    keyframesList.Add(dict);
                }
            }
            else if (param.ParameterType == OFXParameterType.Choice) // Choice
            {
                var p = (OFXChoiceParameter)param;
                foreach (var item in p.Keyframes)
                {
                    var dict = new Dictionary<string, object>
                    {
                        { "Time", item.Time },
                        { "Value", item.Value }
                    };
                    keyframesList.Add(dict);
                }
            }
            else if (param.ParameterType == OFXParameterType.Custom) // Custom
            {
                var p = (OFXCustomParameter)param;
                foreach (var item in p.Keyframes)
                {
                    var dict = new Dictionary<string, object>
                    {
                        { "Time", item.Time },
                        { "Value", item.Value }
                    };
                    keyframesList.Add(dict);
                }
            }
            else if (param.ParameterType == OFXParameterType.Double2D) // Double2D
            {
                var p = (OFXDouble2DParameter)param;
                foreach (var item in p.Keyframes)
                {
                    var dict = new Dictionary<string, object>
                    {
                        { "Time", item.Time }
                    };
                    var tempDict = new Dictionary<string, double>
                    {
                        { "X", item.Value.X },
                        { "Y", item.Value.Y }
                    };
                    dict.Add("Value", tempDict);
                    keyframesList.Add(dict);
                }
            }
            else if (param.ParameterType == OFXParameterType.Double3D) // Double3D
            {
                var p = (OFXDouble3DParameter)param;
                foreach (var item in p.Keyframes)
                {
                    var dict = new Dictionary<string, object>
                    {
                        { "Time", item.Time }
                    };
                    var tempDict = new Dictionary<string, double>
                    {
                        { "X", item.Value.X },
                        { "Y", item.Value.Y },
                        { "Z", item.Value.Z }
                    };
                    dict.Add("Value", tempDict);
                    keyframesList.Add(dict);
                }
            }
            else if (param.ParameterType == OFXParameterType.Double)    // Double
            {
                var p = (OFXDoubleParameter)param;
                foreach (var item in p.Keyframes)
                {
                    var dict = new Dictionary<string, object>
                    {
                        { "Time", item.Time },
                        { "Value", item.Value }
                    };
                    keyframesList.Add(dict);
                }
            }
            else if (param.ParameterType == OFXParameterType.Integer)  // Integer
            {
                var p = (OFXIntegerParameter)param;
                foreach (var item in p.Keyframes)
                {
                    var dict = new Dictionary<string, object>
                    {
                        { "Time", item.Time },
                        { "Value", item.Value }
                    };
                    keyframesList.Add(dict);
                }
            }
            else if (param.ParameterType == OFXParameterType.RGB)       // RGB
            {
                var p = (OFXRGBParameter)param;
                foreach (var item in p.Keyframes)
                {
                    var dict = new Dictionary<string, object>
                    {
                        { "Time", item.Time }
                    };
                    var tempDict = new Dictionary<string, double>
                    {
                        { "R", item.Value.R },
                        { "G", item.Value.G },
                        { "B", item.Value.B }
                    };
                    dict.Add("Value", tempDict);
                    keyframesList.Add(dict);
                }
            }
            else if (param.ParameterType == OFXParameterType.RGBA)      // RGBA
            {
                var p = (OFXRGBAParameter)param;
                foreach (var item in p.Keyframes)
                {
                    var dict = new Dictionary<string, object>
                    {
                        { "Time", item.Time }
                    };
                    var tempDict = new Dictionary<string, double>
                    {
                        { "R", item.Value.R },
                        { "G", item.Value.G },
                        { "B", item.Value.B },
                        { "A", item.Value.A }
                    };
                    dict.Add("Value", tempDict);
                    keyframesList.Add(dict);
                }
            }
            else if (param.ParameterType == OFXParameterType.String)    // String
            {
                var p = (OFXStringParameter)param;
                foreach (var item in p.Keyframes)
                {
                    var dict = new Dictionary<string, object>
                    {
                        { "Time", item.Time },
                        { "Value", item.Value }
                    };
                    keyframesList.Add(dict);
                }
            }
            else if (param.ParameterType == OFXParameterType.Integer2D) // Integer2D
            {
                var p = (OFXInteger2DParameter)param;
                foreach (var item in p.Keyframes)
                {
                    var dict = new Dictionary<string, object>
                    {
                        { "Time", item.Time }
                    };
                    var tempDict = new Dictionary<string, double>
                    {
                        { "X", item.Value.X },
                        { "Y", item.Value.Y }
                    };
                    dict.Add("Value", tempDict);
                    keyframesList.Add(dict);
                }
            }
            else if (param.ParameterType == OFXParameterType.Integer3D) // Integer3D
            {
                var p = (OFXInteger3DParameter)param;
                foreach (var item in p.Keyframes)
                {
                    var dict = new Dictionary<string, object>
                    {
                        { "Time", item.Time }
                    };
                    var tempDict = new Dictionary<string, double>
                    {
                        { "X", item.Value.X },
                        { "Y", item.Value.Y },
                        { "Z", item.Value.Z }
                    };
                    dict.Add("Value", tempDict);
                    keyframesList.Add(dict);
                }
            }

            return keyframesList;
        }
    }
}