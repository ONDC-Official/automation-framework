# City & State Codes

> Reference list of ONDC city codes (STD-code based) and state codes used in API payloads.

---

## Overview

ONDC identifies a city by its telephone **STD code**, prefixed with `std:`. This value goes in `context.city` of every request.

```json
"context": {
  "domain": "ONDC:RET10",
  "country": "IND",
  "city": "std:080",
  "action": "search"
}
```

A few rules to remember:

- Always include the leading `0` of the STD code: `std:080` (Bengaluru), not `std:80`.
- Several cities and towns can share one STD code. The code identifies the area, not one exact town.
- State codes are two-letter codes, used in address and location fields where a state code is expected.

The official source is the [ONDC city & state codes sheet](https://docs.google.com/spreadsheets/d/12A_B-nDtvxyFh_FWDfp85ss2qpb65kZ7/edit?usp=sharing&ouid=118227851397691643336&rtpof=true&sd=true), linked from [ONDC-Official/developer-docs](https://github.com/ONDC-Official/developer-docs/blob/main/City-codes.md). The sheet also has a full **pincode → city → STD code** mapping (over 20,000 pincodes), which is too large to list here.

---

## State Codes

| State / Union Territory | Code |
| ----------------------- | ---- |
| Andaman and Nicobar Islands | `AN` |
| Andhra Pradesh | `AD` |
| Arunachal Pradesh | `AR` |
| Assam | `AS` |
| Bihar | `BR` |
| Chandigarh | `CH` |
| Chattisgarh | `CG` |
| Dadra & Nagar Haveli and Daman & Diu | `DN` |
| Delhi | `DL` |
| Goa | `GA` |
| Gujarat | `GJ` |
| Haryana | `HR` |
| Himachal Pradesh | `HP` |
| Jammu and Kashmir | `JK` |
| Jharkhand | `JH` |
| Karnataka | `KA` |
| Kerala | `KL` |
| Ladakh | `LA` |
| Lakshadweep Islands | `LD` |
| Madhya Pradesh | `MP` |
| Maharashtra | `MH` |
| Manipur | `MN` |
| Meghalaya | `ML` |
| Mizoram | `MZ` |
| Nagaland | `NL` |
| Odisha | `OD` |
| Other Territory | `OT` |
| Pondicherry | `PY` |
| Punjab | `PB` |
| Rajasthan | `RJ` |
| Sikkim | `SK` |
| Tamil Nadu | `TN` |
| Telangana | `TS` |
| Tripura | `TR` |
| Uttar Pradesh | `UP` |
| Uttarakhand | `UK` |
| West Bengal | `WB` |

---

## City Codes

813 city / STD code pairs, grouped by state. Use the value in the **City Code** column as-is in `context.city`.

### Andaman and Nicobar Islands

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Nicobars | 03193 | `std:03193` |
| North and Middle Andaman | 03192 | `std:03192` |
| South Andamans | 03192 | `std:03192` |

### Andhra Pradesh

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Amalapuram | 08856 | `std:08856` |
| Anantapur | 08554 | `std:08554` |
| Chennur | 08737 | `std:08737` |
| Chittoor | 08572 | `std:08572` |
| East Godavari | 0884 | `std:0884` |
| Guntur | 0863 | `std:0863` |
| Krishna | 03472 | `std:03472` |
| Kurnool | 08518 | `std:08518` |
| Prakasam | 08592 | `std:08592` |
| Prakasam | 0870 | `std:0870` |
| Prakasam | 08736 | `std:08736` |
| Razole | 08862 | `std:08862` |
| Spsr Nellore | 0861 | `std:0861` |
| Srikakulam | 08942 | `std:08942` |
| Vijayawada | 0866 | `std:0866` |
| Visakhapatanam | 0891 | `std:0891` |
| Vizianagaram | 08922 | `std:08922` |
| West Godavari | 08812 | `std:08812` |
| Y.s.r. | 08562 | `std:08562` |

### Arunachal Pradesh

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Anjaw | 03804 | `std:03804` |
| Changlang | 03808 | `std:03808` |
| Dibang Valley | 03803 | `std:03803` |
| East Kameng | 03787 | `std:03787` |
| East Siang | 0368 | `std:0368` |
| Kra Daadi | 03783 | `std:03783` |
| Kurung Kumey | 03788 | `std:03788` |
| Leparada | 03795 | `std:03795` |
| Lohit | 03806 | `std:03806` |
| Longding | 03786 | `std:03786` |
| Lower Dibang Valley | 03803 | `std:03803` |
| Lower Siang | 0360 | `std:0360` |
| Lower Subansiri | 03788 | `std:03788` |
| Namsai | 03806 | `std:03806` |
| Pakke Kessang | 03778 | `std:03778` |
| Papum Pare | 0360 | `std:0360` |
| Shi Yomi | 03796 | `std:03796` |
| Siang | 03797 | `std:03797` |
| Tawang | 03794 | `std:03794` |
| Tirap | 03786 | `std:03786` |
| Upper Siang | 03777 | `std:03777` |
| Upper Subansiri | 03792 | `std:03792` |
| West Kameng | 03780 | `std:03780` |
| West Kameng | 03782 | `std:03782` |
| West Siang | 03783 | `std:03783` |

### Assam

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Baksa | 03623 | `std:03623` |
| Baksa | 03624 | `std:03624` |
| Barpeta | 03666 | `std:03666` |
| Biswanath | 03715 | `std:03715` |
| Bongaigaon | 03664 | `std:03664` |
| Cachar | 03842 | `std:03842` |
| Cachar | 03844 | `std:03844` |
| Charaideo | 03842 | `std:03842` |
| Chirang | 03664 | `std:03664` |
| Darrang | 03713 | `std:03713` |
| Dhemaji | 03753 | `std:03753` |
| Dhubri | 03662 | `std:03662` |
| Dibrugarh | 0373 | `std:0373` |
| Dima Hasao | 03673 | `std:03673` |
| Goalpara | 03663 | `std:03663` |
| Golaghat | 03774 | `std:03774` |
| Hailakandi | 03844 | `std:03844` |
| Hojai | 03674 | `std:03674` |
| Jorhat | 0376 | `std:0376` |
| Kamrup | 0361 | `std:0361` |
| Kamrup Metro | 0361 | `std:0361` |
| Karbi Anglong | 03675 | `std:03675` |
| Karimganj | 03843 | `std:03843` |
| Kokrajhar | 03661 | `std:03661` |
| Lakhimpur | 05872 | `std:05872` |
| Majuli | 03775 | `std:03775` |
| Marigaon | 03670 | `std:03670` |
| Nagaon | 03672 | `std:03672` |
| Nalbari | 03624 | `std:03624` |
| Sivasagar | 03772 | `std:03772` |
| Sonitpur | 03712 | `std:03712` |
| South Salmara Mancachar | 03662 | `std:03662` |
| Tinsukia | 0374 | `std:0374` |
| Udalguri | 03711 | `std:03711` |
| West Karbi Anglong | 03675 | `std:03675` |

### Bihar

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Araria | 06453 | `std:06453` |
| Arwal | 06337 | `std:06337` |
| Aurangabad | 0240 | `std:0240` |
| Banka | 06424 | `std:06424` |
| Begusarai | 06243 | `std:06243` |
| Bhagalpur | 0641 | `std:0641` |
| Bhojpur | 06182 | `std:06182` |
| Buxar | 06183 | `std:06183` |
| Darbhanga | 06272 | `std:06272` |
| Dumraon | 06323 | `std:06323` |
| Gaya | 0631 | `std:0631` |
| Gopalganj | 07695 | `std:07695` |
| Hajipur | 06224 | `std:06224` |
| Jamui | 06345 | `std:06345` |
| Jehanabad | 06114 | `std:06114` |
| Kaimur (bhabua) | 06189 | `std:06189` |
| Katihar | 06452 | `std:06452` |
| Khagaria | 06244 | `std:06244` |
| Kishanganj | 07456 | `std:07456` |
| Lakhisarai | 06346 | `std:06346` |
| Madhepura | 06476 | `std:06476` |
| Madhubani | 06276 | `std:06276` |
| Munger | 06344 | `std:06344` |
| Muzaffarpur | 0621 | `std:0621` |
| Nalanda | 06112 | `std:06112` |
| Nawada | 06324 | `std:06324` |
| Pashchim Champaran | 06254 | `std:06254` |
| Patna | 0612 | `std:0612` |
| Purbi Champaran | 06252 | `std:06252` |
| Purnia | 06454 | `std:06454` |
| Rohtas | 06188 | `std:06188` |
| Saharsa | 06478 | `std:06478` |
| Samastipur | 06274 | `std:06274` |
| Saran | 06152 | `std:06152` |
| Sheikhpura | 06341 | `std:06341` |
| Sheohar | 06222 | `std:06222` |
| Sitamarhi | 06226 | `std:06226` |
| Siwan | 06154 | `std:06154` |
| Supaul | 06473 | `std:06473` |
| Vaishali | 06224 | `std:06224` |

### Chandigarh

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Chandigarh | 0172 | `std:0172` |

### Chhattisgarh

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Balod | 07749 | `std:07749` |
| Baloda Bazar | 07826 | `std:07826` |
| Balrampur | 07831 | `std:07831` |
| Bastar | 07782 | `std:07782` |
| Bemetara | 07824 | `std:07824` |
| Bijapur | 07853 | `std:07853` |
| Bilaspur | 07752 | `std:07752` |
| Dantewada | 07856 | `std:07856` |
| Dhamtari | 07722 | `std:07722` |
| Durg | 0788 | `std:0788` |
| Gariyaband | 07707 | `std:07707` |
| Gaurella Pendra Marwahi | 08476 | `std:08476` |
| Janjgir-champa | 07817 | `std:07817` |
| Jashpur | 07763 | `std:07763` |
| Kabirdham | 07817 | `std:07817` |
| Kanker | 07868 | `std:07868` |
| Kondagaon | 07786 | `std:07786` |
| Korba | 07759 | `std:07759` |
| Korea | 07836 | `std:07836` |
| Mahasamund | 07723 | `std:07723` |
| Mungeli | 07755 | `std:07755` |
| Narayanpur | 07781 | `std:07781` |
| Raigarh | 07762 | `std:07762` |
| Raipur | 0771 | `std:0771` |
| Rajnandgaon | 07744 | `std:07744` |
| Sukma | 07864 | `std:07864` |
| Surajpur | 07775 | `std:07775` |
| Surguja | 07774 | `std:07774` |

### Delhi

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Central | 011 | `std:011` |
| East | 011 | `std:011` |
| Hauz Khas | 011 | `std:011` |
| New Delhi | 011 | `std:011` |
| North | 011 | `std:011` |
| North East | 011 | `std:011` |
| North West | 011 | `std:011` |
| Shahdara | 011 | `std:011` |
| South | 011 | `std:011` |
| South East | 011 | `std:011` |
| South West | 011 | `std:011` |
| West | 011 | `std:011` |

### Goa

| City | STD Code | City Code |
| ---- | -------- | --------- |
| North Goa | 0832 | `std:0832` |
| South Goa | 0832 | `std:0832` |

### Gujarat

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Ahmadabad | 079 | `std:079` |
| Amreli | 02792 | `std:02792` |
| Anand | 02692 | `std:02692` |
| Anjar | 02836 | `std:02836` |
| Arvalli | 02774 | `std:02774` |
| Banas Kantha | 02742 | `std:02742` |
| Bharuch | 02642 | `std:02642` |
| Bhavnagar | 0278 | `std:0278` |
| Botad | 02849 | `std:02849` |
| Chhotaudepur | 02669 | `std:02669` |
| Dang | 02631 | `std:02631` |
| Dehgam Taluka | 02716 | `std:02716` |
| Devbhumi Dwarka | 02833 | `std:02833` |
| Dohad | 02673 | `std:02673` |
| Gandhidham | 02836 | `std:02836` |
| Gandhinagar | 079 | `std:079` |
| Gir Somnath | 02876 | `std:02876` |
| Jamnagar | 0288 | `std:0288` |
| Junagadh | 0285 | `std:0285` |
| Kachchh | 02832 | `std:02832` |
| Kheda | 02694 | `std:02694` |
| Mahesana | 02762 | `std:02762` |
| Mahisagar | 02672 | `std:02672` |
| Morbi | 02822 | `std:02822` |
| Nakhatrana | 02835 | `std:02835` |
| Narmada | 02649 | `std:02649` |
| Navsari | 02637 | `std:02637` |
| Panch Mahals | 02672 | `std:02672` |
| Patan | 07621 | `std:07621` |
| Porbandar | 0286 | `std:0286` |
| Rajkot | 0281 | `std:0281` |
| Sabar Kantha | 02772 | `std:02772` |
| Sabar Kantha | 02778 | `std:02778` |
| Surat | 0261 | `std:0261` |
| Surendranagar | 02752 | `std:02752` |
| Tapi | 02628 | `std:02628` |
| Vadodara | 0265 | `std:0265` |
| Valsad | 02632 | `std:02632` |

### Haryana

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Ambala | 0171 | `std:0171` |
| Bahadurgarh | 01276 | `std:01276` |
| Bhiwani | 01664 | `std:01664` |
| Charki Dadri | 01250 | `std:01250` |
| Faridabad | 0129 | `std:0129` |
| Fatehabad | 01667 | `std:01667` |
| Gurugram | 0124 | `std:0124` |
| Haryana | 0172 | `std:0172` |
| Hisar | 01662 | `std:01662` |
| Jhajjar | 01251 | `std:01251` |
| Jind | 01681 | `std:01681` |
| Kaithal | 01746 | `std:01746` |
| Karnal | 0184 | `std:0184` |
| Kurukshetra | 01744 | `std:01744` |
| Mahendragarh | 01285 | `std:01285` |
| Nuh | 01267 | `std:01267` |
| Palwal | 01275 | `std:01275` |
| Panchkula | 0172 | `std:0172` |
| Panipat | 0180 | `std:0180` |
| Rewari | 01274 | `std:01274` |
| Rohtak | 01262 | `std:01262` |
| Sirsa | 05334 | `std:05334` |
| Sonipat | 0130 | `std:0130` |
| Yamunanagar | 01732 | `std:01732` |

### Himachal Pradesh

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Bilaspur | 07752 | `std:07752` |
| Chamba | 01376 | `std:01376` |
| Hamirpur | 05282 | `std:05282` |
| Kangra | 01892 | `std:01892` |
| Kinnaur | 01786 | `std:01786` |
| Kullu | 01902 | `std:01902` |
| Lahul and Spiti | 01900 | `std:01900` |
| Mandi | 01905 | `std:01905` |
| Shimla | 0177 | `std:0177` |
| Sirmaur | 01702 | `std:01702` |
| Solan | 01792 | `std:01792` |
| Una | 02875 | `std:02875` |

### Jammu and Kashmir

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Anantnag | 01932 | `std:01932` |
| Bandipora | 01957 | `std:01957` |
| Baramulla | 01952 | `std:01952` |
| Budgam | 01951 | `std:01951` |
| Doda | 01996 | `std:01996` |
| Ganderbal | 0194 | `std:0194` |
| Jammu | 0191 | `std:0191` |
| Kathua | 01922 | `std:01922` |
| Kishtwar | 01995 | `std:01995` |
| Kulgam | 01931 | `std:01931` |
| Kupwara | 01955 | `std:01955` |
| Poonch | 01965 | `std:01965` |
| Pulwama | 01933 | `std:01933` |
| Rajouri | 01962 | `std:01962` |
| Ramban | 01998 | `std:01998` |
| Reasi | 01991 | `std:01991` |
| Samba | 01923 | `std:01923` |
| Shopian | 01921 | `std:01921` |
| Srinagar | 0194 | `std:0194` |
| Udhampur | 01992 | `std:01992` |

### Jharkhand

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Azadnagar | 06422 | `std:06422` |
| Bokaro | 06542 | `std:06542` |
| Chatra | 06541 | `std:06541` |
| Deoghar | 06432 | `std:06432` |
| Dhanbad | 0326 | `std:0326` |
| Dumka | 06434 | `std:06434` |
| East Singhbhum | 0657 | `std:0657` |
| Garhwa | 06561 | `std:06561` |
| Giridih | 06532 | `std:06532` |
| Godda | 06422 | `std:06422` |
| Gumla | 06524 | `std:06524` |
| Hazaribagh | 06546 | `std:06546` |
| Jamtara | 06433 | `std:06433` |
| Khunti | 06528 | `std:06528` |
| Koderma | 06534 | `std:06534` |
| Latehar | 06565 | `std:06565` |
| Lohardaga | 06526 | `std:06526` |
| Pakur | 06435 | `std:06435` |
| Palamu | 06562 | `std:06562` |
| Ramgarh | 06553 | `std:06553` |
| Ranchi | 0651 | `std:0651` |
| Sahebganj | 06436 | `std:06436` |
| Saraikela Kharsawan | 06597 | `std:06597` |
| Simdega | 06525 | `std:06525` |
| West Singhbhum | 06582 | `std:06582` |

### Karnataka

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Anekal | 08110 | `std:08110` |
| Bagalkote | 08354 | `std:08354` |
| Bailhongal | 08288 | `std:08288` |
| Ballari | 08392 | `std:08392` |
| Bangalore | 080 | `std:080` |
| Belagavi | 0831 | `std:0831` |
| Bengaluru Rural | 080 | `std:080` |
| Bengaluru Urban | 080 | `std:080` |
| Bidar | 08482 | `std:08482` |
| Chamarajanagara | 08226 | `std:08226` |
| Chikkaballapura | 08156 | `std:08156` |
| Chikkamagaluru | 08262 | `std:08262` |
| Chitradurga | 08194 | `std:08194` |
| Dakshina Kannada | 0824 | `std:0824` |
| Davangere | 08192 | `std:08192` |
| Dharwad | 0836 | `std:0836` |
| Gadag | 08372 | `std:08372` |
| Gaviopuram Extension | 080 | `std:080` |
| Hassan | 08172 | `std:08172` |
| Haveri | 08375 | `std:08375` |
| Kalaburagi | 08472 | `std:08472` |
| Kodagu | 08272 | `std:08272` |
| Kolar | 08152 | `std:08152` |
| Koppal | 08539 | `std:08539` |
| Mandya | 08232 | `std:08232` |
| Mysuru | 0821 | `std:0821` |
| Nayandahalli | 080 | `std:080` |
| Raichur | 08532 | `std:08532` |
| Ramanagara | 080 | `std:080` |
| Shivamogga | 08182 | `std:08182` |
| Tumakuru | 0816 | `std:0816` |
| Udupi | 0820 | `std:0820` |
| Uttara Kannada | 08382 | `std:08382` |
| Vasanthnagar | 080 | `std:080` |
| Vijayapura | 08352 | `std:08352` |
| Yadgir | 08473 | `std:08473` |

### Kerala

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Alappuzha | 0477 | `std:0477` |
| Ernakulam | 0484 | `std:0484` |
| Idukki | 04868 | `std:04868` |
| Kannur | 0497 | `std:0497` |
| Kasaragod | 04994 | `std:04994` |
| Kollam | 0474 | `std:0474` |
| Kottayam | 0481 | `std:0481` |
| Kozhikode | 0495 | `std:0495` |
| Malappuram | 0494 | `std:0494` |
| Palakkad | 0491 | `std:0491` |
| Pathanamthitta | 0468 | `std:0468` |
| Thiruvananthapuram | 0471 | `std:0471` |
| Thrissur | 0487 | `std:0487` |
| Wayanad | 04935 | `std:04935` |

### Ladakh

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Kargil | 01985 | `std:01985` |
| Leh Ladakh | 01982 | `std:01982` |

### Lakshadweep

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Lakshadweep District | 04896 | `std:04896` |

### Madhya Pradesh

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Agar Malwa | 07362 | `std:07362` |
| Alirajpur | 07394 | `std:07394` |
| Anuppur | 07629 | `std:07629` |
| Ashoknagar | 07543 | `std:07543` |
| Balaghat | 07632 | `std:07632` |
| Barwani | 07290 | `std:07290` |
| Betul | 07141 | `std:07141` |
| Bhind | 07534 | `std:07534` |
| Bhopal | 0755 | `std:0755` |
| Burhanpur | 07325 | `std:07325` |
| Chhatarpur | 07682 | `std:07682` |
| Chhindwara | 07162 | `std:07162` |
| Damoh | 07812 | `std:07812` |
| Datia | 07522 | `std:07522` |
| Dewas | 07272 | `std:07272` |
| Dhar | 07292 | `std:07292` |
| Dindori | 07644 | `std:07644` |
| Guna | 07542 | `std:07542` |
| Gwalior | 0751 | `std:0751` |
| Harda | 07577 | `std:07577` |
| Hoshangabad | 07574 | `std:07574` |
| Indore | 0731 | `std:0731` |
| Jabalpur | 0761 | `std:0761` |
| Jhabua | 07392 | `std:07392` |
| Katni | 07622 | `std:07622` |
| Khandwa | 0733 | `std:0733` |
| Khargone | 07282 | `std:07282` |
| Mandla | 07642 | `std:07642` |
| Mandsaur | 07422 | `std:07422` |
| Morena | 07532 | `std:07532` |
| Narsinghpur | 07792 | `std:07792` |
| Neemuch | 07423 | `std:07423` |
| Niwari | 07680 | `std:07680` |
| Panna | 07732 | `std:07732` |
| Raisen | 07482 | `std:07482` |
| Rajgarh | 07372 | `std:07372` |
| Ratlam | 07412 | `std:07412` |
| Rewa | 07662 | `std:07662` |
| Sagar | 07582 | `std:07582` |
| Satna | 07672 | `std:07672` |
| Sehore | 07562 | `std:07562` |
| Seoni | 07692 | `std:07692` |
| Shahdol | 07652 | `std:07652` |
| Shajapur | 07364 | `std:07364` |
| Sheopur | 07530 | `std:07530` |
| Shivpuri | 07492 | `std:07492` |
| Sidhi | 07822 | `std:07822` |
| Singrauli | 07805 | `std:07805` |
| Tikamgarh | 07683 | `std:07683` |
| Ujjain | 0734 | `std:0734` |
| Umaria | 07625 | `std:07625` |
| Vidisha | 07592 | `std:07592` |

### Maharashtra

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Ahmednagar | 0241 | `std:0241` |
| Akola | 0724 | `std:0724` |
| Amravati | 0721 | `std:0721` |
| Aurangabad | 0240 | `std:0240` |
| Beed | 02442 | `std:02442` |
| Bhandara | 07184 | `std:07184` |
| Bhiwandi | 02522 | `std:02522` |
| Buldhana | 07262 | `std:07262` |
| Chandrapur | 07172 | `std:07172` |
| Dhule | 02562 | `std:02562` |
| Gadchiroli | 07132 | `std:07132` |
| Gondia | 07182 | `std:07182` |
| Hingoli | 02456 | `std:02456` |
| Jalgaon | 0257 | `std:0257` |
| Jalna | 02482 | `std:02482` |
| Kolhapur | 0231 | `std:0231` |
| Kothrud | 022 | `std:022` |
| Latur | 02382 | `std:02382` |
| Mumbai | 022 | `std:022` |
| Mumbai Suburban | 022 | `std:022` |
| Nagpur | 022 | `std:022` |
| Nagpur | 0712 | `std:0712` |
| Nanded | 02462 | `std:02462` |
| Nandurbar | 02564 | `std:02564` |
| Nashik | 0253 | `std:0253` |
| Osmanabad | 02472 | `std:02472` |
| Palghar | 02525 | `std:02525` |
| Parbhani | 02452 | `std:02452` |
| Pune | 020 | `std:020` |
| Raigad | 02194 | `std:02194` |
| Ratnagiri | 02352 | `std:02352` |
| Sangli | 0233 | `std:0233` |
| Satara | 02162 | `std:02162` |
| Sindhudurg | 02362 | `std:02362` |
| Solapur | 0217 | `std:0217` |
| Thane | 022 | `std:022` |
| Ulhasnagar | 022 | `std:022` |
| Vasai | 0250 | `std:0250` |
| Wardha | 07152 | `std:07152` |
| Washim | 07252 | `std:07252` |
| Yavatmal | 07232 | `std:07232` |

### Manipur

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Bishnupur | 03244 | `std:03244` |
| Chandel | 03872 | `std:03872` |
| Churachandpur | 03874 | `std:03874` |
| Imphal East | 0385 | `std:0385` |
| Imphal West | 0385 | `std:0385` |
| Jiribam | 03876 | `std:03876` |
| Kakching | 03848 | `std:03848` |
| Kangpokpi | 03880 | `std:03880` |
| Noney | 0377 | `std:0377` |
| Pherzawl | 03874 | `std:03874` |
| Senapati | 03878 | `std:03878` |
| Tamenglong | 03877 | `std:03877` |
| Tengnoupal | 03872 | `std:03872` |
| Thoubal | 03848 | `std:03848` |
| Ukhrul | 03845 | `std:03845` |

### Meghalaya

| City | STD Code | City Code |
| ---- | -------- | --------- |
| East Garo Hills | 03651 | `std:03651` |
| East Jaintia Hills | 03651 | `std:03651` |
| East Khasi Hills | 0364 | `std:0364` |
| North Garo Hills | 03651 | `std:03651` |
| Ri Bhoi | 03622 | `std:03622` |
| South Garo Hills | 03651 | `std:03651` |
| South West Garo Hills | 03651 | `std:03651` |
| South West Khasi Hills | 03655 | `std:03655` |
| West Garo Hills | 03651 | `std:03651` |
| West Jaintia Hills | 03651 | `std:03651` |
| West Khasi Hills | 03656 | `std:03656` |

### Mizoram

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Aizawl | 0389 | `std:0389` |
| Champhai | 03831 | `std:03831` |
| Hnahthial | 0372 | `std:0372` |
| Khawzawl | 03837 | `std:03837` |
| Kolasib | 03837 | `std:03837` |
| Lawngtlai | 03835 | `std:03835` |
| Lunglei | 0372 | `std:0372` |
| Mamit | 0389 | `std:0389` |
| Saiha | 03835 | `std:03835` |
| Saitual | 0389 | `std:0389` |
| Serchhip | 03838 | `std:03838` |

### Nagaland

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Dimapur | 03862 | `std:03862` |
| Kiphire | 03863 | `std:03863` |
| Kohima | 0370 | `std:0370` |
| Longleng | 03869 | `std:03869` |
| Mokokchung | 0369 | `std:0369` |
| Mon | 03869 | `std:03869` |
| Noklak | 03876 | `std:03876` |
| Peren | 03870 | `std:03870` |
| Phek | 03865 | `std:03865` |
| Tuensang | 03861 | `std:03861` |
| Wokha | 03860 | `std:03860` |
| Zunheboto | 03867 | `std:03867` |

### Odisha

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Anugul | 06764 | `std:06764` |
| Balangir | 06652 | `std:06652` |
| Baleshwar | 06782 | `std:06782` |
| Bargarh | 06646 | `std:06646` |
| Bhadrak | 06784 | `std:06784` |
| Boudh | 06841 | `std:06841` |
| Cuttack | 0671 | `std:0671` |
| Deogarh | 02904 | `std:02904` |
| Dhenkanal | 06762 | `std:06762` |
| Gajapati | 06815 | `std:06815` |
| Ganjam | 06811 | `std:06811` |
| Jagatsinghapur | 0671 | `std:0671` |
| Jagatsinghapur | 06724 | `std:06724` |
| Jajapur | 06726 | `std:06726` |
| Jharsuguda | 06645 | `std:06645` |
| Kalahandi | 06670 | `std:06670` |
| Kandhamal | 06842 | `std:06842` |
| Kendrapara | 06727 | `std:06727` |
| Kendujhar | 06728 | `std:06728` |
| Kendujhar | 06766 | `std:06766` |
| Khordha | 06752 | `std:06752` |
| Khordha | 06755 | `std:06755` |
| Koraput | 06852 | `std:06852` |
| Malkangiri | 06861 | `std:06861` |
| Mayurbhanj | 06792 | `std:06792` |
| Nabarangpur | 06858 | `std:06858` |
| Nayagarh | 03223 | `std:03223` |
| Nuapada | 06678 | `std:06678` |
| Puri | 06752 | `std:06752` |
| Rayagada | 06856 | `std:06856` |
| Sambalpur | 0663 | `std:0663` |
| Sonepur | 06158 | `std:06158` |
| Sundargarh | 06622 | `std:06622` |

### Puducherry

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Karaikal | 04368 | `std:04368` |
| Mahe | 0490 | `std:0490` |
| Pondicherry | 0413 | `std:0413` |
| Yanam | 0884 | `std:0884` |

### Punjab

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Amritsar | 0183 | `std:0183` |
| Barnala | 01679 | `std:01679` |
| Bathinda | 0164 | `std:0164` |
| Faridkot | 01639 | `std:01639` |
| Fatehgarh Sahib | 01763 | `std:01763` |
| Fazilka | 01638 | `std:01638` |
| Firozepur | 01632 | `std:01632` |
| Gurdaspur | 01874 | `std:01874` |
| Hoshiarpur | 01882 | `std:01882` |
| Jalandhar | 0181 | `std:0181` |
| Kapurthala | 01822 | `std:01822` |
| Ludhiana | 0161 | `std:0161` |
| Malerkotla | 01675 | `std:01675` |
| Mansa | 01652 | `std:01652` |
| Moga | 01636 | `std:01636` |
| Pathankot | 0186 | `std:0186` |
| Patiala | 0175 | `std:0175` |
| Rupnagar | 01881 | `std:01881` |
| S.a.s Nagar | 0172 | `std:0172` |
| Sangrur | 01672 | `std:01672` |
| Shahid Bhagat Singh Nagar | 01823 | `std:01823` |
| Sri Muktsar Sahib | 01633 | `std:01633` |
| Tarn Taran | 01852 | `std:01852` |

### Rajasthan

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Ajmer | 0145 | `std:0145` |
| Alwar | 0144 | `std:0144` |
| Banswara | 02962 | `std:02962` |
| Baran | 07453 | `std:07453` |
| Barmer | 02982 | `std:02982` |
| Bharatpur | 07835 | `std:07835` |
| Bhilwara | 01482 | `std:01482` |
| Bikaner | 0151 | `std:0151` |
| Bundi | 0747 | `std:0747` |
| Chittorgarh | 01472 | `std:01472` |
| Churu | 01562 | `std:01562` |
| Dausa | 01427 | `std:01427` |
| Dholpur | 05642 | `std:05642` |
| Dungarpur | 02964 | `std:02964` |
| Ganganagar | 0154 | `std:0154` |
| Hanumangarh | 01552 | `std:01552` |
| Jaipur | 0141 | `std:0141` |
| Jaisalmer | 02992 | `std:02992` |
| Jalore | 02973 | `std:02973` |
| Jhalawar | 07432 | `std:07432` |
| Jhunjhunu | 01592 | `std:01592` |
| Jodhpur | 0291 | `std:0291` |
| Karauli | 07464 | `std:07464` |
| Kota | 07753 | `std:07753` |
| Nagaur | 01582 | `std:01582` |
| Pali | 07816 | `std:07816` |
| Pratapgarh | 05342 | `std:05342` |
| Rajsamand | 02952 | `std:02952` |
| Sawai Madhopur | 07462 | `std:07462` |
| Sikar | 01572 | `std:01572` |
| Sirohi | 02972 | `std:02972` |
| Tonk | 01432 | `std:01432` |
| Udaipur | 0294 | `std:0294` |

### Sikkim

| City | STD Code | City Code |
| ---- | -------- | --------- |
| East District | 03592 | `std:03592` |
| North District | 03592 | `std:03592` |
| South District | 03595 | `std:03595` |
| West District | 03595 | `std:03595` |

### Tamil Nadu

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Ariyalur | 04329 | `std:04329` |
| Chengalpattu | 04114 | `std:04114` |
| Chennai | 044 | `std:044` |
| Coimbatore | 0422 | `std:0422` |
| Cuddalore | 04142 | `std:04142` |
| Dharmapuri | 04342 | `std:04342` |
| Dindigul | 0451 | `std:0451` |
| Erode | 0424 | `std:0424` |
| Hosur | 04344 | `std:04344` |
| Kallakurichi | 04151 | `std:04151` |
| Kanchipuram | 04112 | `std:04112` |
| Kanniyakumari | 04652 | `std:04652` |
| Karur | 04324 | `std:04324` |
| Krishnagiri | 04343 | `std:04343` |
| Madurai | 0452 | `std:0452` |
| Mayiladuthurai | 04364 | `std:04364` |
| Nagapattinam | 04365 | `std:04365` |
| Namakkal | 04286 | `std:04286` |
| Perambalur | 04328 | `std:04328` |
| Pudukkottai | 04322 | `std:04322` |
| Ramanathapuram | 04567 | `std:04567` |
| Ranipet | 04172 | `std:04172` |
| Salem | 0427 | `std:0427` |
| Sivaganga | 04575 | `std:04575` |
| Tenkasi | 04633 | `std:04633` |
| Thanjavur | 04362 | `std:04362` |
| The Nilgiris | 0423 | `std:0423` |
| Theni | 04546 | `std:04546` |
| Thiruvallur | 044 | `std:044` |
| Thiruvarur | 04366 | `std:04366` |
| Tiruchirappalli | 0431 | `std:0431` |
| Tirunelveli | 0462 | `std:0462` |
| Tirupathur | 04577 | `std:04577` |
| Tiruppur | 0421 | `std:0421` |
| Tiruvallur | 044 | `std:044` |
| Tiruvannamalai | 04175 | `std:04175` |
| Tuticorin | 0461 | `std:0461` |
| Udumalpet | 0421 | `std:0421` |
| Vellore | 0416 | `std:0416` |
| Villupuram | 04146 | `std:04146` |
| Virudhunagar | 04562 | `std:04562` |

### Telangana

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Adilabad | 08732 | `std:08732` |
| Bhadradri Kothagudem | 08743 | `std:08743` |
| Bhadradri Kothagudem | 08744 | `std:08744` |
| Hyderabad | 040 | `std:040` |
| Jagitial | 08724 | `std:08724` |
| Jagitial | 08728 | `std:08728` |
| Jagitial | 0878 | `std:0878` |
| Jangoan | 08457 | `std:08457` |
| Jangoan | 08716 | `std:08716` |
| Jangoan | 08719 | `std:08719` |
| Jayashankar Bhupalapally | 0870 | `std:0870` |
| Jayashankar Bhupalapally | 08719 | `std:08719` |
| Jayashankar Bhupalapally | 08728 | `std:08728` |
| Jogulamba Gadwal | 08546 | `std:08546` |
| Kamareddy | 08468 | `std:08468` |
| Karimnagar | 0878 | `std:0878` |
| Khammam | 08742 | `std:08742` |
| Kumuram Bheem Asifabad | 08732 | `std:08732` |
| Kumuram Bheem Asifabad | 08733 | `std:08733` |
| Kumuram Bheem Asifabad | 08736 | `std:08736` |
| Kumuram Bheem Asifabad | 08738 | `std:08738` |
| Mahabubabad | 08719 | `std:08719` |
| Mahabubnagar | 08542 | `std:08542` |
| Mancherial | 08736 | `std:08736` |
| Medak | 08452 | `std:08452` |
| Medchal Malkajgiri | 040 | `std:040` |
| Medchal Malkajgiri | 08418 | `std:08418` |
| Mulugu | 0870 | `std:0870` |
| Mulugu | 08715 | `std:08715` |
| Mulugu | 08716 | `std:08716` |
| Mulugu | 08744 | `std:08744` |
| Nagarkurnool | 08540 | `std:08540` |
| Nalgonda | 08682 | `std:08682` |
| Narayanpet | 08506 | `std:08506` |
| Nirmal | 08734 | `std:08734` |
| Nizamabad | 08462 | `std:08462` |
| Peddapalli | 08728 | `std:08728` |
| Rajanna Sircilla | 08457 | `std:08457` |
| Rajanna Sircilla | 08723 | `std:08723` |
| Rajanna Sircilla | 08724 | `std:08724` |
| Rajanna Sircilla | 0878 | `std:0878` |
| Ranga Reddy | 040 | `std:040` |
| Ranga Reddy | 08414 | `std:08414` |
| Ranga Reddy | 08416 | `std:08416` |
| Ranga Reddy | 08418 | `std:08418` |
| Ranga Reddy | 08540 | `std:08540` |
| Ranga Reddy | 08542 | `std:08542` |
| Ranga Reddy | 08682 | `std:08682` |
| Sangareddy | 08455 | `std:08455` |
| Siddipet | 08457 | `std:08457` |
| Suryapet | 08684 | `std:08684` |
| Vikarabad | 08416 | `std:08416` |
| Wanaparthy | 08543 | `std:08543` |
| Warangal Rural | 0870 | `std:0870` |
| Warangal Rural | 08715 | `std:08715` |
| Warangal Rural | 08716 | `std:08716` |
| Warangal Rural | 08719 | `std:08719` |
| Warangal Urban | 0870 | `std:0870` |
| Warangal Urban | 08716 | `std:08716` |
| Warangal Urban | 0878 | `std:0878` |
| Yadadri Bhuvanagiri | 08585 | `std:08585` |
| Yadadri Bhuvanagiri | 08684 | `std:08684` |
| Yadadri Bhuvanagiri | 08685 | `std:08685` |

### The Dadra and Nagar Haveli and Daman and Diu

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Dadra and Nagar Haveli | 0260 | `std:0260` |
| Daman | 0260 | `std:0260` |
| Diu | 02875 | `std:02875` |

### Tripura

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Dhalai | 03826 | `std:03826` |
| Gomati | 03821 | `std:03821` |
| Khowai | 03825 | `std:03825` |
| North Tripura | 03822 | `std:03822` |
| North Tripura | 03824 | `std:03824` |
| Sepahijala | 0381 | `std:0381` |
| South Tripura | 03823 | `std:03823` |
| Unakoti | 03824 | `std:03824` |
| West Tripura | 0381 | `std:0381` |

### Uttar Pradesh

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Agra | 0562 | `std:0562` |
| Aligarh | 0571 | `std:0571` |
| Ambedkar Nagar | 05271 | `std:05271` |
| Amethi | 05368 | `std:05368` |
| Amroha | 05922 | `std:05922` |
| Auraiya | 05683 | `std:05683` |
| Ayodhya | 05278 | `std:05278` |
| Azamgarh | 05462 | `std:05462` |
| Baghpat | 01234 | `std:01234` |
| Bahraich | 05252 | `std:05252` |
| Ballia | 05498 | `std:05498` |
| Balrampur | 07831 | `std:07831` |
| Banda | 07583 | `std:07583` |
| Barabanki | 05248 | `std:05248` |
| Bareilly | 0581 | `std:0581` |
| Basti | 05542 | `std:05542` |
| Bhadohi | 05414 | `std:05414` |
| Bijnor | 01342 | `std:01342` |
| Budaun | 05832 | `std:05832` |
| Bulandshahr | 05732 | `std:05732` |
| Chandauli | 05412 | `std:05412` |
| Chitrakoot | 05191 | `std:05191` |
| Deoria | 05568 | `std:05568` |
| Etah | 05742 | `std:05742` |
| Etawah | 05688 | `std:05688` |
| Farrukhabad | 05692 | `std:05692` |
| Fatehpur | 05240 | `std:05240` |
| Firozabad | 05612 | `std:05612` |
| Gautam Buddha Nagar | 0120 | `std:0120` |
| Ghaziabad | 0120 | `std:0120` |
| Ghazipur | 0548 | `std:0548` |
| Gonda | 05262 | `std:05262` |
| Gorakhpur | 0551 | `std:0551` |
| Hamirpur | 05282 | `std:05282` |
| Hapur | 0122 | `std:0122` |
| Hardoi | 05852 | `std:05852` |
| Hathras | 05722 | `std:05722` |
| Jalaun | 05168 | `std:05168` |
| Jaunpur | 05452 | `std:05452` |
| Jhansi | 0510 | `std:0510` |
| Kakori | 05732 | `std:05732` |
| Kannauj | 05694 | `std:05694` |
| Kanpur Dehat | 05113 | `std:05113` |
| Kanpur Nagar | 0512 | `std:0512` |
| Kasganj | 05744 | `std:05744` |
| Kaushambi | 05331 | `std:05331` |
| Kheri | 05872 | `std:05872` |
| Kushi Nagar | 05564 | `std:05564` |
| Lalitpur | 05176 | `std:05176` |
| Lucknow | 0522 | `std:0522` |
| Maharajganj | 05523 | `std:05523` |
| Mahoba | 05281 | `std:05281` |
| Mainpuri | 05672 | `std:05672` |
| Mathura | 0565 | `std:0565` |
| Mau | 0547 | `std:0547` |
| Meerut | 0121 | `std:0121` |
| Mirzapur | 05442 | `std:05442` |
| Moradabad | 0591 | `std:0591` |
| Muzaffarnagar | 0131 | `std:0131` |
| Noida | 01189 | `std:01189` |
| Pilibhit | 05882 | `std:05882` |
| Pratapgarh | 05342 | `std:05342` |
| Prayagraj | 0532 | `std:0532` |
| Rae Bareli | 0535 | `std:0535` |
| Rampur | 0595 | `std:0595` |
| Saharanpur | 0132 | `std:0132` |
| Sambhal | 05923 | `std:05923` |
| Sant Kabeer Nagar | 05547 | `std:05547` |
| Shahjahanpur | 05842 | `std:05842` |
| Shamli | 01398 | `std:01398` |
| Shravasti | 05252 | `std:05252` |
| Siddharth Nagar | 05544 | `std:05544` |
| Sitapur | 07834 | `std:07834` |
| Sonbhadra | 05444 | `std:05444` |
| Sultanpur | 01828 | `std:01828` |
| Unnao | 0515 | `std:0515` |
| Varanasi | 0542 | `std:0542` |

### Uttarakhand

| City | STD Code | City Code |
| ---- | -------- | --------- |
| Almora | 05962 | `std:05962` |
| Bageshwar | 05963 | `std:05963` |
| Chamoli | 01372 | `std:01372` |
| Champawat | 05962 | `std:05962` |
| Dehradun | 0135 | `std:0135` |
| Haldwani | 05946 | `std:05946` |
| Haridwar | 01334 | `std:01334` |
| Nainital | 05942 | `std:05942` |
| Pauri Garhwal | 01368 | `std:01368` |
| Pithoragarh | 05964 | `std:05964` |
| Rudra Prayag | 01364 | `std:01364` |
| Tehri Garhwal | 01376 | `std:01376` |
| Udam Singh Nagar | 05944 | `std:05944` |
| Uttar Kashi | 01374 | `std:01374` |

### West Bengal

| City | STD Code | City Code |
| ---- | -------- | --------- |
| 24 Paraganas North | 033 | `std:033` |
| 24 Paraganas South | 033 | `std:033` |
| Alipurduar | 03564 | `std:03564` |
| Bankura | 03242 | `std:03242` |
| Birbhum | 03462 | `std:03462` |
| Bohar | 033 | `std:033` |
| Calcutta | 033 | `std:033` |
| Coochbehar | 03582 | `std:03582` |
| Darjeeling | 0354 | `std:0354` |
| Dinajpur Dakshin | 03522 | `std:03522` |
| Dinajpur Uttar | 03523 | `std:03523` |
| Hooghly | 033 | `std:033` |
| Howrah | 033 | `std:033` |
| Jalpaiguri | 03561 | `std:03561` |
| Jhargram | 03221 | `std:03221` |
| Kalimpong | 03552 | `std:03552` |
| Kolkata | 033 | `std:033` |
| Maldah | 03512 | `std:03512` |
| Medinipur East | 03228 | `std:03228` |
| Medinipur West | 03222 | `std:03222` |
| Murshidabad | 03483 | `std:03483` |
| Nadia | 03472 | `std:03472` |
| Nadia | 03473 | `std:03473` |
| Nadia | 03474 | `std:03474` |
| North 24 Parganas | 033 | `std:033` |
| Paschim Bardhaman | 0341 | `std:0341` |
| Purba Bardhaman | 0342 | `std:0342` |
| Purulia | 03252 | `std:03252` |
| South 24 Parganas | 033 | `std:033` |
| South Bengal | 0341 | `std:0341` |
