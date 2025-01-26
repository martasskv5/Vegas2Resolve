import os
import json

# Define the folder containing the JSON files
folder = r'C:/Users/martinko/OneDrive - MSFT/Documents/VFX/Vegas Pro/Exported Presets'
dictionary_path = r"C:/Users/martinko/OneDrive - MSFT/Documents/VFX/Vegas Pro/Exported Presets/!!!! UniqueIDs.json"
ofx_ids_path = r"C:/Users/martinko/OneDrive - MSFT/Documents/VFX/Vegas Pro/Exported Presets/!!!! OFXIDS.txt"

# Load the dictionary file
with open(dictionary_path, 'r') as file:
    dictionary_data = json.load(file)

# Load the OFX IDs from the text file
with open(ofx_ids_path, 'r') as file:
    ofx_ids = {line.strip() for line in file}

# Initialize a dictionary to store unique descriptions and their IDs from the dictionary
unique_descriptions = {item['Description'].strip(): item['ID'] for item in dictionary_data}

def match_ofx_id(description):
    # Try to match the description with an OFX ID 
    matched_id = next((ofx_id for ofx_id in ofx_ids if description in ofx_id), None) # basicly works only for sapphire
    if not matched_id:
        # Additional logic for BCC and BCC+ effects
        if description.startswith("BCC "):
            base_desc = description.replace("BCC ", "").replace(" ", "_")
            print(base_desc)
            matched_id = next((ofx_id for ofx_id in ofx_ids if ofx_id.startswith("ofx.com.borisfx.BCC") and ofx_id.endswith(base_desc)), None)
        elif description.startswith("BCC+"):
            base_desc = description[4].lower() + description[5:]
            base_desc = base_desc.replace("BCC+", "ofx.com.borisfx.bcc_dft.ofx.").replace(" ", "")
            print(base_desc)
            matched_id = next((ofx_id for ofx_id in ofx_ids if base_desc in ofx_id), None)
        elif description.startswith("uni."):
            base_desc = description.replace("uni.", "").replace(" ", "_") + "_OFX"
            print(base_desc)
            matched_id = next((ofx_id for ofx_id in ofx_ids if ofx_id.startswith("ofx.com.redgiantsoftware.Universe_") and ofx_id.endswith(base_desc)), None)
        elif description.startswith("Ignite "):
            base_desc = description.replace("Ignite ", "").replace(" ", "")
            print(base_desc)
            matched_id = next((ofx_id for ofx_id in ofx_ids if ofx_id.startswith("ofx.com.FXHOME.HitFilm") and ofx_id.endswith(base_desc)), None)
        elif description.startswith("NewBlue"):
            base_desc = description.replace("NewBlue ", "").replace(" ", "").replace("-OpenFX", "")
            print(base_desc)
            matched_id = next((ofx_id for ofx_id in ofx_ids if ofx_id.startswith("ofx.com.NewBlue") and ofx_id.endswith(base_desc)), None)            
    return matched_id

# Iterate over each file in the folder
for filename in os.listdir(folder):
    if filename.endswith('.json'):
        filepath = os.path.join(folder, filename)
        with open(filepath, 'r') as file:
            data = json.load(file)
            for item in data:
                description = item.get('Description')
                if description:
                    description = description.strip()
                    if description not in unique_descriptions:
                        matched_id = match_ofx_id(description)
                        unique_descriptions[description] = matched_id
                        dictionary_data.append({"Description": description, "ID": matched_id})
                    elif unique_descriptions[description] is None:
                        matched_id = match_ofx_id(description)
                        if matched_id:
                            unique_descriptions[description] = matched_id
                            for dict_item in dictionary_data:
                                if dict_item['Description'].strip() == description:
                                    dict_item['ID'] = matched_id
                                    break

# Save the updated dictionary file
with open(dictionary_path, 'w') as file:
    json.dump(dictionary_data, file, indent=4)

print("Dictionary updated successfully.")