<?php
header("Content-Type: image/png");
passthru("sudo -u pi DISPLAY=:0 bash -c \"scrot - | cat\" 2>&1");
