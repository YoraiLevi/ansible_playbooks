function Convert-StringCMD{
param([string]$psString = "")
# https://www.robvanderwoude.com/escapechars.php
 $escapeChacater = "^"
 $replacementDictionary = @{
                            "%" = "%%";
                            "&" = "^&";
                            "<" = "^<";
                            ">" = "^>";
                            "|" = "^|";
                          }
  $psString = $psString.Replace("$escapeChacater","$escapeChacater$escapeChacater"); #Escape escape character before inserting more escape characters that might be escaped
  foreach($element in $replacementDictionary.GetEnumerator()){
    $psString = $psString.Replace($element.Name,$element.Value)
  }
  $psString
}