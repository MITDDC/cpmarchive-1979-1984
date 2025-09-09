(defun
  cpmname (num name)
  (implode (append (explodec "cpm;ar")(explodec num)
	  (explodec ":")(explodec name))))

(defun sf (num name) (saf (cpmname num name)))
