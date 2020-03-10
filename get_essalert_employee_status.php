<?php
/*
 * get_essalert_employee_status.php - Generate a CSV file of all Senate
 *   employees, including whether or not the employee has entered his/her
 *   emergency contact information via ESS/Alert.
 *
 * Project: shell-scripts
 * Author: Ken Zalewski
 * Organization: New York State Senate
 * Date: 2020-03-09
 *
 * Note: This PHP script expects an XML file as input, and the XML file must
 *       be in the format required by SendWordNow.  This is the XML file that
 *       we transfer to SendWordNow once a day.  It can be generated using the
 *       following command from the ESS project:
 *
 *       $ bin/swnftp.sh --no-ftp --pretty --keep-tmpfile
 *
 *       The resulting XML file will be in the /tmp directory.
*/

$prog = $argv[0];

if ($argc != 2) {
  error_log("Usage: $prog xml_file");
  exit(1);
}

$xml_file = $argv[1];

if (!file_exists($xml_file)) {
  error_log("$prog: $xml_file: File not found");
  exit(1);
}

$xml = simplexml_load_file($xml_file);

if ($xml === false) {
  error_log("$prog: $xml_file: Unable to parse XML file");
  exit(1);
}


// Sort according to department, then according to last name.
function cmp($a, $b)
{
  if ($a['Department'] < $b['Department']) {
    return -1;
  }
  elseif ($a['Department'] > $b['Department']) {
    return 1;
  }
  elseif ($a['LastName'] < $b['LastName']) {
    return -1;
  }
  elseif ($a['LastName'] > $b['LastName']) {
    return 1;
  }
  elseif ($a['FirstName'] < $b['FirstName']) {
    return -1;
  }
  elseif ($a['FirstName'] > $b['FirstName']) {
    return 1;
  }
  else {
    return 0;
  }
}


$registered_contacts = 0;
$unregistered_contacts = 0;
$total_contacts = 0;
$contacts = [];

echo "DEPARTMENT,LAST_NAME,FIRST_NAME,TITLE,ADDRESS,CITY,ZIP,WORK_PHONE,WORK_EMAIL,REGISTERED\n";

foreach ($xml->batchContactList->contact as $contact) {
  $cinfo = [];
  $has_nonwork_contact_point = 0;

  foreach ($contact->contactField as $field) {
    $fldname = (string) $field['name'];
    if ($fldname == 'CustomField') {
      $fldname = (string) $field['customName'];
    }
    $cinfo[$fldname] = (string) $field;
  }

  foreach ($contact->contactPointList->contactPoint as $cpoint) {
    $cplabel = $cpvalue = '';
    foreach ($cpoint->contactPointField as $cpfield) {
      $cpfname = (string) $cpfield['name'];
      if ($cpfname == 'Label') {
        $cplabel = (string) $cpfield;
      }
      elseif ($cpfname == 'Address' || $cpfname == 'Number') {
        $cpvalue = (string) $cpfield;
      }
    }

    if ($cplabel != '') {
      $cinfo[$cplabel] = $cpvalue;
      if ($cplabel != 'Work Email' && $cplabel != 'Work Phone') {
        $has_nonwork_contact_point = 1;
      }
    }
  }

  $cinfo['Registered'] = $has_nonwork_contact_point;

  $contacts[] = $cinfo;

  $registered_contacts = $registered_contacts + $has_nonwork_contact_point;
  $unregistered_contacts = $unregistered_contacts + !$has_nonwork_contact_point;
  $total_contacts++;
}

usort($contacts, "cmp");

foreach ($contacts as $contact) {
  $got_first = false;
  foreach (['Department', 'LastName', 'FirstName', 'Title', 'Address1', 'City', 'PostalCode', 'Work Phone', 'Work Email', 'Registered'] as $fldname) {
    if ($got_first) {
      echo ',';
    }
    echo '"'.$contact[$fldname].'"';
    $got_first = true;
  }
  echo "\n";
}

error_log("Total contacts: $total_contacts");
error_log("Registered contacts: $registered_contacts");
error_log("Unregistered contacts: $unregistered_contacts");

exit (0);
